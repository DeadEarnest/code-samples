module Flashing.Tests

open Flashing
open Flashing.BootMode
open Flashing.BootMode.LowLevel
open Flashing.NormalMode
open Flashing.NormalMode.LowLevel
open Flashing.IntelHex
open Flashing.IntelHex.LowLevel



open Expecto
open Expecto.Flip
open System.IO
open FsCheck
open Hopac
open Hopac.Infixes
open Newtonsoft.Json
open Newtonsoft.Json.Linq




let intelHexText = [
    ":020000040800F2" // extended linear address
    ":10000000987A0320850200082F410008153D00085A" // data
    ":10001000987A0320850200082F410008153D00075D" // data
    ":020000040801F1" // extended linear address
    ":100000000590052004F08AFBF5E60898401C08904E" // data
    ":100010001190052004F08AFBF5E60898401C08904E" // data
    ":04000005080001B539" // program start address
    ":00000001FF" // end of file
]

let parsedHex = (
    "080001B5", // program start address
    dict [
        // (address, data)
        ("08000000", "987A0320850200082F410008153D0008")
        ("08000010", "987A0320850200082F410008153D0007")
        ("08010000", "0590052004F08AFBF5E60898401C0890")
        ("08010010", "1190052004F08AFBF5E60898401C0890")
    ]
)




let bytesReadShifted (stream : Stream) count =
    stream.Seek(int64 -count, SeekOrigin.Current) |> ignore
    bytesRead stream count

let bytesSendSetup (bytesToSend : byte []) =
    use stream = new MemoryStream(bytesToSend.Length + 1)
    bytesSend stream bytesToSend
    bytesReadShifted stream (bytesToSend.Length + 1)

let initialByteSendSetup deviceType =
    let stream = new MemoryStream(2)
    let sendTask =
        async {initialByteSend stream deviceType} |> Async.Catch |> Async.StartAsTask
    Async.Sleep(100) |> Async.RunSynchronously
    stream, sendTask




let normalMode = testList "normal mode functions" [

    // TODO: разобраться, почему тест выдаёт stack overflow
    //testCase "replyGet | gives reply with matching rid" <|
    //fun _ ->
    //    let streamSource = hopacStreamSrcGet (new MemoryStream(10_000))
    //    let stream = Stream.Src.tap streamSource
    //    let jToken = JToken.Parse("""{"rid":"f-c0","token":"ABCD"}""")
    //    Stream.Src.value streamSource jToken |> run
    //    adminTokenRead stream "f-c0"
    //    |> Expect.equal "" "ABCD"
    ]




let bootMode = testList "boot mode functions" [

    testCase "initialByteSend, LED chip case | throws if byte not acknowledged" <|
    fun _ ->
        let stream, sendTask = initialByteSendSetup LedChip
        stream.Write([|0x00uy|], 0, 1)
        sendTask.Wait()

        let expectedError = FlashingExn "expected ACK byte [|0x79|], but got [|0uy|]"
        sendTask.Result
        |> Expect.equal "" (Choice2Of2 expectedError)

    testCase "initialByteSend, LED chip case | sends initial byte" <|
    fun _ ->
        let stream, sendTask = initialByteSendSetup LedChip

        bytesReadShifted stream 1
        |> Expect.equal "" [|initialByte|]

        stream.Write([|ackByte|], 0, 1)
        sendTask.Wait()




    testCase "bytesSend | does nothing when given 0 bytes" <|
    fun _ ->
        use stream = new MemoryStream(1)
        bytesSend stream [||]
        stream.Seek(0L, SeekOrigin.Current)
        |> Expect.equal "" 0L

    testProperty "bytesSend | sends multiple bytes" <|
    function
        | [||] | [|_|] -> true
        | bytesToSend ->
            let sentBytes = bytesSendSetup bytesToSend
            bytesToSend = Array.take bytesToSend.Length sentBytes
    
    testProperty "bytesSend | sends multiple bytes XOR" <|
    function
        | [||] | [|_|] -> true
        | bytesToSend ->
            let sentBytes = bytesSendSetup bytesToSend
            Array.fold (^^^) 0x00uy sentBytes = 0x00uy

    testProperty "bytesSend | sends single byte" <|
    fun byteToSend ->
        let sentBytes = bytesSendSetup [|byteToSend|]
        sentBytes.[0] = byteToSend

    testProperty "bytesSend | sends single byte complement" <|
    fun byteToSend ->
        let sentBytes = bytesSendSetup [|byteToSend|]
        sentBytes.[0] ^^^ sentBytes.[1] = 0xFFuy
]




let intelHex = testList "Intel hex file parsing" [

    testCase "memoryBlockChunk | divides by given size and gives address | #1" <|
    fun _ ->
        let expected = seq [
            ("08000000", "987A0320")
            ("08000004", "85020008")
            ("08000008", "2F410008")
            ("0800000C", "153D0008")
        ]
        memoryBlockChunk ("08000000", "987A0320850200082F410008153D0008") 4
        |> Expect.sequenceEqual "" expected
        ()

    testCase "memoryBlockChunk | divides by given size and gives address | #2" <|
    fun _ ->
        let expected = seq [
            ("08000000", "987A032085020008")
            ("08000008", "2F410008153D0008")
        ]
        memoryBlockChunk ("08000000", "987A0320850200082F410008153D0008") 8
        |> Expect.sequenceEqual "" expected
        ()



    testCase "memoryGetContinuous | merges continuous memory sectors" <|
    fun _ ->
        let _, memory = textRead intelHexText
        let expected = dict [
            ("08000000", "987A0320850200082F410008153D0008"
                + "987A0320850200082F410008153D0007")
            ("08010000", "0590052004F08AFBF5E60898401C0890"
                + "1190052004F08AFBF5E60898401C0890")
        ]
        memoryGetContinuous memory
        |> Expect.sequenceEqual "" expected




    testCase "continuousAddresGet | gives subj" <|
    fun _ ->
        let _, memory = textRead intelHexText

        continuousAddresGet memory "08000000"
        |> Expect.equal "" ["08000000"; "08000010"]
        
        continuousAddresGet memory "08010000"
        |> Expect.equal "" ["08010000"; "08010010"]




    testCase "intelHexTextParse | hex text" <|
    fun _ ->
        let startAddr, memory = textRead intelHexText
        
        Expect.equal "" (fst parsedHex)  startAddr
        Expect.sequenceEqual "" (snd parsedHex) memory




    testCase "lineParse | record type = extended linear addr | #1" <|
    fun _ ->
        let line = ":020000040800F2"
        let expected = dict [
            ("byteCount", "02")
            ("addr", "0000")
            ("recordType", "04")
            ("data", "0800")
            ("checksum", "F2")
        ]

        lineParse line
        |> Expect.sequenceEqual "" expected

    testCase "lineParse | record type = extended linear addr | #2" <|
    fun _ ->
        let line = ":0408000411112222A4"
        let expected = dict [
            ("byteCount", "04")
            ("addr", "0800")
            ("recordType", "04")
            ("data", "11112222")
            ("checksum", "A4")
        ]

        lineParse line
        |> Expect.sequenceEqual "" expected

    testCase "lineParse | record type = data | #1" <|
    fun _ ->
        let line = ":10000000987A0320850200082F410008153D00085A"
        let expected = dict [
            ("byteCount", "10")
            ("addr", "0000")
            ("recordType", "00")
            ("data", "987A0320850200082F410008153D0008")
            ("checksum", "5A")
        ]

        lineParse line
        |> Expect.sequenceEqual "" expected

    testCase "lineParse | record type = data | #2" <|
    fun _ ->
        let line = ":0495B00004F10000C2"   
        let expected = dict [
            ("byteCount", "04")
            ("addr", "95B0")
            ("recordType", "00")
            ("data", "04F10000")
            ("checksum", "C2")
        ]

        lineParse line
        |> Expect.sequenceEqual "" expected

    testCase "lineParse | end of file record" <|
    fun _ ->
        let line1 = ":00000001FF"
        let expected = dict [
            ("byteCount", "00")
            ("addr", "0000")
            ("recordType", "01")
            ("data", "")
            ("checksum", "FF")
        ]
        let actual = lineParse line1

        Expect.sequenceEqual "" expected actual
]




[<Tests>]
let tests = testList "flashing" [
    intelHex
    normalMode
    bootMode
]
