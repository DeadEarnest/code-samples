module Flashing

open Newtonsoft.Json
open Newtonsoft.Json.Linq
open Hopac
open Hopac.Infixes

open System.IO
open System.Net.Sockets
open System.Globalization
open System.Linq
open System.Text.RegularExpressions
open System.Collections.Generic




exception FlashingExn of string

let exnToResult func =
    fun () ->
        try Ok (func ())
        with
        | FlashingExn msg -> Error msg
        | _ -> reraise()

let hexStrToBytes (str : string) =
    [|for i in 0..2..str.Length - 1 ->
        System.Byte.Parse(str.Substring(i, 2), NumberStyles.HexNumber)
    |]




module BootMode =

    module LowLevel =

        let memoryReadCmd = 0x11uy
        let memoryWriteCmd = 0x31uy
        let getChipIdCmd = 0x02uy
        let memoryEraseExtendedCmd = 0x44uy
        let memoryEraseCmd = 0x43uy
        let programStartCmd = 0x21uy

        let ackByte = 0x79uy
        let initialByte = 0x7Fuy
        let eraseFirstDataBankSeq = [|0xFFuy; 0xFEuy|]
        let codeSectorsCnt = 0x79uy
        

        let byteSendWithComplement (stream : Stream) byteToSend =
            let bytesToSend = [|byteToSend; ~~~byteToSend|]
            stream.Write(bytesToSend, 0, bytesToSend.Length)


        let bytesSendWithXor (stream : Stream) (bytes : byte []) =
            let checksum = Array.fold (^^^) 0x00uy bytes
            let bytesToSend = [| yield! bytes; checksum|]
            stream.Write(bytesToSend, 0, bytesToSend.Length)


        let bytesSend (stream : Stream) (bytes : byte []) =
            match bytes.Length with
            | 0 -> ()
            | 1 -> byteSendWithComplement stream bytes.[0]
            | _ -> bytesSendWithXor stream bytes


        let bytesRead (stream : Stream) count =
            let buffer = Array.create count 0x00uy
            stream.Read(buffer, 0, count) |> ignore
            buffer

        
        let ackCheck stream =
            let readBytes = bytesRead stream 1

            match readBytes with
            | [|x|] when x = ackByte -> ()
            | _ ->
                let msg =
                    sprintf "expected ACK byte [|0x%02X|], but got %A" ackByte readBytes
                raise (FlashingExn msg)

   
        let memoryRead stream startAddr byteCount =
            bytesSend stream [|memoryReadCmd|]
            ackCheck stream
        
            hexStrToBytes startAddr |> bytesSend stream
            ackCheck stream
    
            bytesSend stream [|(byte (byteCount - 1))|]
            ackCheck stream
    
            bytesRead stream (int byteCount)
    

        let memoryWrite stream startAddr (bytesToWrite : byte []) = 
            bytesSend stream [|memoryWriteCmd|]
            ackCheck stream
    
            hexStrToBytes startAddr |> bytesSend stream
            ackCheck stream
    
            let bytesToSend = [|(byte (bytesToWrite.Length - 1)); yield! bytesToWrite|]
            bytesSend stream bytesToSend
            ackCheck stream
    
            memoryRead stream startAddr bytesToWrite.Length
        

        type DeviceType =
            | LedChip // STM32F469xx
            | Switch // STM32F103xx


        let chipIdToChipType = function
            | [|0x04uy; 0x34uy|] -> LedChip
            | [|0x04uy; 0x10uy|] -> Switch
            | x ->
                let msg = sprintf "unknown chip id: %A" x
                raise (FlashingExn msg)

        let chipTypeGet stream = 
            bytesSend stream [|getChipIdCmd|]
            ackCheck stream
    
            let byteCount = (bytesRead stream 1).[0] |> int |> (+) 1
            let id = bytesRead stream byteCount
            ackCheck stream

            chipIdToChipType id
            
            
        let memoryEraseExtended stream =
            bytesSend stream [|memoryEraseExtendedCmd|]
            ackCheck stream
                
            eraseFirstDataBankSeq |> bytesSend stream
            ackCheck stream


        let memoryErase stream =
            bytesSend stream [|memoryEraseCmd|]
            ackCheck stream

            bytesSend stream [|codeSectorsCnt; yield! [0uy..codeSectorsCnt]|]
            ackCheck stream


    open LowLevel
    
    let initialByteSend (stream : Stream) deviceType =
        stream.Write([|initialByte|], 0, 1)
        ackCheck stream
        match deviceType with
        | LedChip -> ()
        | Switch -> // баг выключателя, посылаем initialByte дважды
            stream.Write([|initialByte|], 0, 1)
            bytesRead stream 1 |> ignore
       

    let oldProgramErase stream =
        match chipTypeGet stream with
        | LedChip -> memoryEraseExtended stream
        | Switch -> memoryErase stream
    

    let dataWriteToMemory (stream : Stream) (data : (string * string) list) =
        let mutable blockNum = 1

        for entry in data do
            let addr = fst entry
            let bytesToWrite = snd entry |> hexStrToBytes
            bytesToWrite = memoryWrite stream addr bytesToWrite
                |> printfn "block %d/%d write succeeded: %b" blockNum data.Length
            blockNum <- blockNum + 1


    let programStart (stream : Stream) startAddr =
        bytesSend stream [|programStartCmd|]
        ackCheck stream
    
        hexStrToBytes startAddr |> bytesSend stream
        ackCheck stream




module NormalMode =

    module LowLevel =

        let jsonSend (stream : Stream) jsonString =
            let bytes = System.Text.Encoding.UTF8.GetBytes(jsonString : string)
            do stream.Write(bytes, 0, bytes.Length)


        let hopacStreamSrcGet (stream : Stream) = 
            let streamSource = Stream.Src.create ()
            let reader = new StreamReader(stream)
            let jsonReader = new JsonTextReader(reader, SupportMultipleContent = true)

            job {
                if jsonReader.ReadAsync().Result then
                    let! token = JToken.ReadFromAsync(jsonReader)
                    do! Stream.Src.value streamSource token
            } |> Stream.indefinitely |> Stream.consumeFun id

            streamSource


        let adminTokenRead (stream : Stream<JToken>) rid =
            let reply =
                stream
                |> Stream.skipWhileFun ^ fun jToken -> jToken.["rid"].ToString() <> rid
                |> Stream.values |> Job.map ^ fun jToken -> jToken.["token"].ToString()
                |> run
            reply
        

        let adminTokenGet (stream : Stream) (deviceCfg : IDictionary<string, string>) =
            let reader = new StreamReader(stream)
            let jsonReader = new JsonTextReader(reader, SupportMultipleContent = true)

            let c0Request =
                """{"rid":"f-c0","type_command":"C0","""
                + (sprintf "\"serial_number\":\"%s\",\"id\":%d,\"device\":\"%s\"}"
                    deviceCfg.["serial_number"] (int deviceCfg.["id"])
                    deviceCfg.["device"])
            jsonSend stream c0Request

            Async.Sleep(500) |> Async.RunSynchronously
            let c0Reply = JToken.ReadFrom(jsonReader)
            let adminToken = c0Reply.["token"].ToString()

            printfn "Admin token is: %s" adminToken
            adminToken


        let x2CommandSend (stream : Stream) adminToken =
            let x2command =
                sprintf """{"rid":"f-x2","type_command":"X2","token":"%s"}"""
                <| adminToken
            jsonSend stream x2command
            Async.Sleep(1000) |> Async.RunSynchronously


    open LowLevel
    
    let startBootMode stream deviceCfg =
        try 
            adminTokenGet stream deviceCfg
            |> x2CommandSend stream
        with
        | _ as exn ->
            let msg = "could not start boot mode, exception : " + exn.Message
            raise (FlashingExn msg)

    


module IntelHex =

    module LowLevel =

        let data = "00"
        let endOfFile = "01"
        let extLinAddr = "04"
        let startLinAddr = "05"


        let (|Regex|_|) pattern text =
            let m = Regex.Match(text, pattern)
            if m.Success then Some(List.tail [for g in m.Groups -> g.Value])
            else None


        let lineParse line =
            match line with
            | Regex @":(..)(....)(..)(.*)(..)"
                [byteCount; addr; recordType; data; checksum] ->
                    dict [
                        ("byteCount", byteCount)
                        ("addr", addr)
                        ("recordType", recordType)
                        ("data", data)
                        ("checksum", checksum)
                    ]
            | _ -> dict []

        
        let addrIncrease addr byteCount =
            System.Int64.Parse(addr, NumberStyles.HexNumber)
            |> (+) (int64 byteCount)
            |> sprintf "%08X"


        let memoryBlockChunk (startAddr : string, data : string) byteCount =
            let chunkSize = byteCount * 2
            query {
                for idx in 0 .. data.Length - 1 do
                groupBy (idx / chunkSize) into group
                let groupAddr = addrIncrease startAddr (group.Key * byteCount)
                let data =
                    group |> Seq.fold (fun curr i -> curr + data.[i].ToString()) ""
                select (groupAddr, data)
            }

            
        let memoryChunk (memory : IDictionary<string, string>) byteCount =
            [
                for block in memory do
                    yield! memoryBlockChunk (block.Key, block.Value) byteCount
            ]


        let rec continuousAddresGet (memory : IDictionary<string, string>) startAddr =
            let mutable nextAddr = startAddr

            [ while memory.ContainsKey nextAddr do
                yield nextAddr
                nextAddr <- addrIncrease nextAddr (memory.[nextAddr].Length / 2)
            ]
    

        let dataGetMerged (memory : IDictionary<string, string>) addres =
            List.fold (fun currData addr -> currData + memory.[addr]) "" addres


        let memoryCutOut (memory : IDictionary<string, string>) addres =
            let mutable remainingMemory = new Dictionary<string, string>(memory)
            for addr in addres do remainingMemory.Remove(addr) |> ignore
            remainingMemory

        
        let textRead text =
            let mutable programStartAddr = "08000000"
            let mutable relativeAddr = "0000"

            let memory = dict [
                for line in text do
                    let tokens = lineParse line

                    match tokens.["recordType"] with
                    | x when x = extLinAddr ->
                        relativeAddr <- tokens.["data"]
                    | x when x = data ->
                        yield (relativeAddr + tokens.["addr"], tokens.["data"])
                    | x when x = startLinAddr ->
                        programStartAddr <-tokens.["data"]
                    | x when x = endOfFile ->
                        ()
                    | x ->
                        let msg = sprintf "unknown record type '%s' in Intel hex file" x
                        raise (FlashingExn msg)
            ]

            programStartAddr, memory

            
        let memoryGetContinuous (memory : IDictionary<string, string>) =
            let mutable remainingMemory = new Dictionary<string, string>(memory)

            dict [
                while remainingMemory.Count <> 0 do
                    let addr = remainingMemory.Keys.First()
                    let contAddres = continuousAddresGet remainingMemory addr
                    let data = dataGetMerged remainingMemory contAddres
                    remainingMemory <- memoryCutOut remainingMemory contAddres
                    yield addr, data
            ]


    open LowLevel

    let maxBytesInMessage = 256


    let textParse text =
        let programStartAddr, rawMemory = textRead text
        let properlyPackagedMemory =
            rawMemory |> memoryGetContinuous |> memoryChunk <| maxBytesInMessage
        programStartAddr, properlyPackagedMemory




module Main =

    module LowLevel =

        let deviceConnect (ip : System.Net.IPAddress) port =
            let client = new TcpClient()
            client.Connect(ip, port)
            let stream = client.GetStream()
            stream
    

        let newProgramLoad (stream : Stream) (startAddr, memory) =
            stream.ReadTimeout <- 25000
            BootMode.oldProgramErase stream
            BootMode.dataWriteToMemory stream memory
            BootMode.programStart stream startAddr

    open LowLevel

    let bootModeFlash parsedHex ip port deviceCfg deviceType =
        let stream = deviceConnect ip port
        stream.ReadTimeout <- 2000
        BootMode.initialByteSend stream deviceType
        newProgramLoad stream parsedHex


    let normalModeFlash parsedHex ip port deviceCfg deviceType =
        let stream = deviceConnect ip port
        stream.ReadTimeout <- 2000
        NormalMode.startBootMode stream deviceCfg
        BootMode.initialByteSend stream deviceType
        newProgramLoad stream parsedHex