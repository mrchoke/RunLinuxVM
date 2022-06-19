/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app delegate that sets up and starts the virtual machine.
 */

import Virtualization


var vmBundlePath = NSHomeDirectory() + "/LinuxVM.bundle/"
let mainDiskImagePath = vmBundlePath + "Disk.img"
let efiVariableStorePath = vmBundlePath + "NVRAM"
let machineIdentifierPath = vmBundlePath + "MachineIdentifier"
var cpuNums: Int = 0
var screenWidth = 1920
var screenHeight = 1080
var imageSize: UInt64 = 10
var ramSize: UInt64 = 4

struct Resolution {
    var width: Int
    var height: Int
}

let Resolutions: [String: Resolution] = [
    "hd": Resolution(width: 1280, height: 720),
    "fhd": Resolution(width: 1920, height: 1080),
    "2k": Resolution(width: 2560, height: 1440),
    "4k": Resolution(width: 4096, height: 2160)
]

enum OptionCode: Int32 {
    case c = 0x63
    case d = 0x64
    case h = 0x68
    case m = 0x6D
    case r = 0x72
    case p = 0x70
    case firstLongOption = 0x100
}

extension StaticString {
    var ccharPointer: UnsafePointer<CChar> {
        let rawPointer = UnsafeRawPointer(utf8Start)
        return rawPointer.bindMemory(to: CChar.self, capacity: utf8CodeUnitCount)
    }
}

let longOpts: [option] = [
    option(name: ("cpu" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.c.rawValue),
    option(name: ("disk" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.d.rawValue),
    option(name: ("help" as StaticString).ccharPointer, has_arg: no_argument, flag: nil, val: OptionCode.h.rawValue),
    option(name: ("resolution" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.r.rawValue),
    option(name: ("mem" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.m.rawValue),
    option(name: ("path" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.p.rawValue),
    option()
]



@main
class AppDelegate: NSObject, NSApplicationDelegate, VZVirtualMachineDelegate {
    
    @IBOutlet var window: NSWindow!
    
    @IBOutlet weak var virtualMachineView: VZVirtualMachineView!
    
    private var virtualMachine: VZVirtualMachine!
    
    private var installerISOPath: URL?
    
    private var needsInstall = true
    
    override init() {
        
        while case let opt = getopt_long(CommandLine.argc, CommandLine.unsafeArgv, "hc:d:r:m:p:", longOpts, nil), opt != -1 {
            switch opt {
            
            case OptionCode.c.rawValue:
                let cpuarg = (Int(String(cString: optarg)) ?? 1)
                
                if cpuarg > 0 && cpuarg < ProcessInfo.processInfo.processorCount {
                    cpuNums = cpuarg
                } else {
                    fatalError("CPU number [1..\(ProcessInfo.processInfo.processorCount - 1)]")
                }
                
            case OptionCode.d.rawValue:
                imageSize = UInt64(Int(String(cString: optarg)) ?? 0)
                
            case OptionCode.m.rawValue:
                ramSize = UInt64(Int(String(cString: optarg)) ?? 0)
                
            case OptionCode.p.rawValue:
                vmBundlePath = String(cString: optarg)
                
            case OptionCode.r.rawValue:
                let optres = String(cString: optarg)
                
                if let res = Resolutions[optres]{
                    screenWidth = res.width
                    screenHeight = res.height
                } else {
                    fatalError("Invalid resolution \(optres): hd, fhd, 2k and 4k")
                }
                
                
            case OptionCode.h.rawValue:
            
                print("""
                    Options available:
                     --cpu, -c: number of cpus [1..\(ProcessInfo.processInfo.processorCount - 1)]
                     --disk, -d: disk image size in GB
                     --mem, -m: memory size in GB
                     --path, -p: bundle path with tailing slash eg. /path/to/Debian.bundle/
                     --resolution, -r: screen resolution preset [hd, fhd, 2k, 4k]
                     --help, -h: show this help
                    """)
                exit(0)
            
            default:
                print("")
            }
        }
        
        super.init()
    }
    
    private func createVMBundle() {
        do {
            try FileManager.default.createDirectory(atPath: vmBundlePath, withIntermediateDirectories: false)
        } catch {
            fatalError("Failed to create “GUI Linux VM.bundle.”")
        }
    }
    
    // Create an empty disk image for the virtual machine.
    private func createMainDiskImage() {
        let diskCreated = FileManager.default.createFile(atPath: mainDiskImagePath, contents: nil, attributes: nil)
        if !diskCreated {
            fatalError("Failed to create the main disk image.")
        }
        
        guard let mainDiskFileHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: mainDiskImagePath)) else {
            fatalError("Failed to get the file handle for the main disk image.")
        }
        
        do {
           
            try mainDiskFileHandle.truncate(atOffset: imageSize * 1024 * 1024 * 1024)
        } catch {
            fatalError("Failed to truncate the main disk image.")
        }
    }
    
    // MARK: Create device configuration objects for the virtual machine.
    
    private func createBlockDeviceConfiguration() -> VZVirtioBlockDeviceConfiguration {
        guard let mainDiskAttachment = try? VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: mainDiskImagePath), readOnly: false) else {
            fatalError("Failed to create main disk attachment.")
        }
        
        let mainDisk = VZVirtioBlockDeviceConfiguration(attachment: mainDiskAttachment)
        return mainDisk
    }
    
    private func computeCPUCount() -> Int {
        let totalAvailableCPUs = ProcessInfo.processInfo.processorCount
        
        var virtualCPUCount = totalAvailableCPUs <= 1 ? 1 : cpuNums > 0 ? cpuNums  : totalAvailableCPUs - 1
        virtualCPUCount = max(virtualCPUCount, VZVirtualMachineConfiguration.minimumAllowedCPUCount)
        virtualCPUCount = min(virtualCPUCount, VZVirtualMachineConfiguration.maximumAllowedCPUCount)
        
        return virtualCPUCount
    }
    
    private func computeMemorySize() -> UInt64 {
        var memorySize = (ramSize * 1024 * 1024 * 1024) as UInt64
        memorySize = max(memorySize, VZVirtualMachineConfiguration.minimumAllowedMemorySize)
        memorySize = min(memorySize, VZVirtualMachineConfiguration.maximumAllowedMemorySize)
        
        return memorySize
    }
    
    private func createAndSaveMachineIdentifier() -> VZGenericMachineIdentifier {
        let machineIdentifier = VZGenericMachineIdentifier()
        
        // Store the machine identifier to disk so you can retrieve it for subsequent boots.
        try! machineIdentifier.dataRepresentation.write(to: URL(fileURLWithPath: machineIdentifierPath))
        return machineIdentifier
    }
    
    private func retrieveMachineIdentifier() -> VZGenericMachineIdentifier {
        // Retrieve the machine identifier.
        guard let machineIdentifierData = try? Data(contentsOf: URL(fileURLWithPath: machineIdentifierPath)) else {
            fatalError("Failed to retrieve the machine identifier data.")
        }
        
        guard let machineIdentifier = VZGenericMachineIdentifier(dataRepresentation: machineIdentifierData) else {
            fatalError("Failed to create the machine identifier.")
        }
        
        return machineIdentifier
    }
    
    private func createEFIVariableStore() -> VZEFIVariableStore {
        guard let efiVariableStore = try? VZEFIVariableStore(creatingVariableStoreAt: URL(fileURLWithPath: efiVariableStorePath)) else {
            fatalError("Failed to create the EFI variable store.")
        }
        
        return efiVariableStore
    }
    
    private func retrieveEFIVariableStore() -> VZEFIVariableStore {
        if !FileManager.default.fileExists(atPath: efiVariableStorePath) {
            fatalError("EFI variable store does not exist.")
        }
        
        return VZEFIVariableStore(url: URL(fileURLWithPath: efiVariableStorePath))
    }
    
    private func createUSBMassStorageDeviceConfiguration() -> VZUSBMassStorageDeviceConfiguration {
        guard let intallerDiskAttachment = try? VZDiskImageStorageDeviceAttachment(url: installerISOPath!, readOnly: true) else {
            fatalError("Failed to create installer's disk attachment.")
        }
        
        return VZUSBMassStorageDeviceConfiguration(attachment: intallerDiskAttachment)
    }
    
    private func createNetworkDeviceConfiguration() -> VZVirtioNetworkDeviceConfiguration {
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        
        return networkDevice
    }
    
    private func createGraphicsDeviceConfiguration() -> VZVirtioGraphicsDeviceConfiguration {
        let graphicsDevice = VZVirtioGraphicsDeviceConfiguration()
        graphicsDevice.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(widthInPixels: screenWidth, heightInPixels: screenHeight)
        ]
        
        return graphicsDevice
    }
    
    private func createInputAudioDeviceConfiguration() -> VZVirtioSoundDeviceConfiguration {
        let inputAudioDevice = VZVirtioSoundDeviceConfiguration()
        
        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()
        
        inputAudioDevice.streams = [inputStream]
        return inputAudioDevice
    }
    
    private func createOutputAudioDeviceConfiguration() -> VZVirtioSoundDeviceConfiguration {
        let outputAudioDevice = VZVirtioSoundDeviceConfiguration()
        
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        
        outputAudioDevice.streams = [outputStream]
        return outputAudioDevice
    }
    
    private func createSpiceAgentConsoleDeviceConfiguration() -> VZVirtioConsoleDeviceConfiguration {
        let consoleDevice = VZVirtioConsoleDeviceConfiguration()
        
        let spiceAgentPort = VZVirtioConsolePortConfiguration()
        spiceAgentPort.name = VZSpiceAgentPortAttachment.spiceAgentPortName
        spiceAgentPort.attachment = VZSpiceAgentPortAttachment()
        consoleDevice.ports[0] = spiceAgentPort
        
        return consoleDevice
    }
    
    
    private func createRosettaShare(configuration: VZVirtualMachineConfiguration) throws {
        
        let tag = "ROSETTA"
        // let configuration = VZVirtualMachineConfiguration()
        do {
            let _ =  try VZVirtioFileSystemDeviceConfiguration.validateTag(tag)
            let rosettaDirectoryShare = try VZLinuxRosettaDirectoryShare()
            let fileSystemDevice = VZVirtioFileSystemDeviceConfiguration(tag: tag)
            fileSystemDevice.share = rosettaDirectoryShare
            
            configuration.directorySharingDevices = [ fileSystemDevice ]
        } catch {
            fatalError("Rosetta is unavailable")
            
        }
        
        
    }
    
    // MARK: Create the virtual machine configuration and instantiate the virtual machine.
    
    func createVirtualMachine() {
        
        
        let virtualMachineConfiguration = VZVirtualMachineConfiguration()
        
        virtualMachineConfiguration.cpuCount = computeCPUCount()
        virtualMachineConfiguration.memorySize = computeMemorySize()
        
        let platform = VZGenericPlatformConfiguration()
        let bootloader = VZEFIBootLoader()
        let disksArray = NSMutableArray()
        
        if needsInstall {
            // This is a fresh install: Create a new machine identifier and EFI variable store,
            // and configure a USB mass storage device to boot the ISO image.
            platform.machineIdentifier = createAndSaveMachineIdentifier()
            bootloader.variableStore = createEFIVariableStore()
            disksArray.add(createUSBMassStorageDeviceConfiguration())
        } else {
            // The VM is booting from a disk image that already has the OS installed.
            // Retrieve the machine identifier and EFI variable store that were saved to
            // disk during installation.
            platform.machineIdentifier = retrieveMachineIdentifier()
            bootloader.variableStore = retrieveEFIVariableStore()
        }
        
        virtualMachineConfiguration.platform = platform
        virtualMachineConfiguration.bootLoader = bootloader
        
        disksArray.add(createBlockDeviceConfiguration())
        guard let disks = disksArray as? [VZStorageDeviceConfiguration] else {
            fatalError("Invalid disksArray.")
        }
        virtualMachineConfiguration.storageDevices = disks
        
        virtualMachineConfiguration.networkDevices = [createNetworkDeviceConfiguration()]
        virtualMachineConfiguration.graphicsDevices = [createGraphicsDeviceConfiguration()]
        virtualMachineConfiguration.audioDevices = [createInputAudioDeviceConfiguration(), createOutputAudioDeviceConfiguration()]
        
        virtualMachineConfiguration.keyboards = [VZUSBKeyboardConfiguration()]
        virtualMachineConfiguration.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        virtualMachineConfiguration.consoleDevices =  [createSpiceAgentConsoleDeviceConfiguration()]
        do {
            try createRosettaShare(configuration: virtualMachineConfiguration)
        } catch {
            print("Rosetta is unavailable\n")
        }
  
        try! virtualMachineConfiguration.validate()
        virtualMachine = VZVirtualMachine(configuration: virtualMachineConfiguration)
    }
    
    // MARK: Start the virtual machine.
    
    func configureAndStartVirtualMachine() {
        DispatchQueue.main.async {
            self.createVirtualMachine()
            self.virtualMachineView.virtualMachine = self.virtualMachine
            self.virtualMachine.delegate = self
            self.virtualMachine.start(completionHandler: { (result) in
                switch result {
                case let .failure(error):
                    fatalError("Virtual machine failed to start with error: \(error)")
                    
                default:
                    print("Virtual machine successfully started.")
                }
            })
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        
        // If "GUI Linux VM.bundle" doesn't exist, the sample app tries to create
        // one and install Linux onto an empty disk image from the ISO image,
        // otherwise, it tries to directly boot from the disk image inside
        // the "GUI Linux VM.bundle".
        if !FileManager.default.fileExists(atPath: vmBundlePath) {
            needsInstall = true
            createVMBundle()
            createMainDiskImage()
            
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            
            openPanel.begin { (result) -> Void in
                if result == .OK {
                    self.installerISOPath = openPanel.url!
                    self.configureAndStartVirtualMachine()
                } else {
                    fatalError("ISO file not selected.")
                }
            }
        } else {
            needsInstall = false
            configureAndStartVirtualMachine()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: VZVirtualMachineDelegate methods.
    
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        print("Virtual machine did stop with error: \(error.localizedDescription)")
        exit(-1)
    }
    
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        print("Guest did stop virtual machine.")
        exit(0)
    }
    
    func virtualMachine(_ virtualMachine: VZVirtualMachine, networkDevice: VZNetworkDevice, attachmentWasDisconnectedWithError error: Error) {
        print("Netowrk attachment was disconnected with error: \(error.localizedDescription)")
    }
}


