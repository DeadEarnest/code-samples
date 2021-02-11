open Flashing




[<EntryPoint>]
let main argv =
    
    // switch
    //let filePath = "D:/projects/dev/firefly/firefly-docs/stm32/DimmerWiFiSwitch_v1_0.hex"
    //let ip = new System.Net.IPAddress([|192uy; 168uy; 0uy; 251uy|])
    //let port = 8080
    //let deviceCfg = dict [
    //    "device", "Switch1" // device name
    //    "serial_number", "98D863FDEEA2" // device's wi-fi module MAC address
    //    "id", "1" // flashing host's id
    //]
    //let parsedHex = IntelHex.textParse (System.IO.File.ReadAllLines(filePath))
    //Main.normalModeFlash parsedHex ip port deviceCfg BootMode.LowLevel.Switch
    //Main.bootModeFlash parsedHex ip port deviceCfg BootMode.LowLevel.Switch


    // LED strip
    let filePath = "D:/projects/dev/firefly/firefly-docs/stm32/DimmerFireFly_v2_5_1_2020_06_30_rid.hex"
    //let filePath = "D:/projects/dev/firefly/firefly-docs/stm32/DimmerFireFly_v2_5_2020_09_07.hex"
    let ip = new System.Net.IPAddress([|192uy; 168uy; 0uy; 252uy|])
    let port = 8080
    let deviceCfg = dict [
        "device", "LedChip16" // device name
        "serial_number", "FFFFFFFFFFFF" // device's wi-fi module MAC address
        "id", "1" // flashing host's id
    ]
    let parsedHex = IntelHex.textParse (System.IO.File.ReadAllLines(filePath))
    //Main.normalModeFlash parsedHex ip port deviceCfg BootMode.LowLevel.LedChip
    Main.bootModeFlash parsedHex ip port deviceCfg BootMode.LowLevel.LedChip

    0