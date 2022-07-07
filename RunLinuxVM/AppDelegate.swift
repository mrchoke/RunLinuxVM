/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app delegate that sets up and starts the virtual machine.
 */

import Virtualization
import Foundation
import Cocoa

let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
let appPath = Bundle.main.bundleURL.absoluteString

var isoPath: String? = nil
var vmBundlePath = NSHomeDirectory() + "/LinuxVM.bundle/"
let mainDiskImagePath = vmBundlePath + "Disk.img"
var ndDiskImagePath: [String]? = nil
var sharePaths: [String]? = nil
let efiVariableStorePath = vmBundlePath + "NVRAM"
let machineIdentifierPath = vmBundlePath + "MachineIdentifier"
var cpuNums: Int = 0
var screenWidth = 1920
var screenHeight = 1080
var imageSize: UInt64 = 10
var ramSize: UInt64 = 4
var liveMode = false

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
    case R = 0x52
    case S = 0x53
    case c = 0x63
    case d = 0x64
    case h = 0x68
    case i = 0x69
    case l = 0x6C
    case m = 0x6D
    case p = 0x70
    case r = 0x72
    case s = 0x73
    case version
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
    option(name: ("iso" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.i.rawValue),
    option(name: ("live" as StaticString).ccharPointer, has_arg: no_argument, flag: nil, val: OptionCode.l.rawValue),
    option(name: ("mem" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.m.rawValue),
    option(name: ("path" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.p.rawValue),
    option(name: ("raw-imgs" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.R.rawValue),
    option(name: ("resolution" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.r.rawValue),
    option(name: ("share-paths" as StaticString).ccharPointer, has_arg: required_argument, flag: nil, val: OptionCode.S.rawValue),
    option(name: ("version" as StaticString).ccharPointer, has_arg: no_argument, flag: nil, val: OptionCode.version.rawValue),
    option()
]


func cleanPath(path: String) -> String {
    let cpath = path.replacingOccurrences(
        of: "\\s+",
        with: " ",
        options: .regularExpression
    )
        .replacingOccurrences(
            of: "/+",
            with: "/",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespaces)
    return cpath
}

func addTailingSlash(path: String) -> String {
    let cpath = cleanPath(path: path)
    return cpath.hasSuffix("/") ? cpath : cpath + "/"
}

func getOpt() {
    while case let opt = getopt_long(CommandLine.argc, CommandLine.unsafeArgv, "hR:S:c:d:i:lr:m:p:s:", longOpts, nil), opt != -1 {
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
            
        case OptionCode.R.rawValue:
            ndDiskImagePath = [String(cString: optarg)]
            let optDisk = String(cString: optarg)
            ndDiskImagePath = optDisk
                .split(separator: ",")
                .map({ (substring) in
                    return cleanPath(path: String(substring))
                })
            
        case OptionCode.i.rawValue:
            isoPath = cleanPath(path: String(cString: optarg))
            
        case OptionCode.l.rawValue:
            liveMode = true
            
        case OptionCode.m.rawValue:
            ramSize = UInt64(Int(String(cString: optarg)) ?? 0)
            
        case OptionCode.p.rawValue:
            vmBundlePath = addTailingSlash(path: String(cString: optarg))
            
        case OptionCode.r.rawValue:
            let optres = String(cString: optarg)
            
            if let res = Resolutions[optres]{
                screenWidth = res.width
                screenHeight = res.height
            } else {
                fatalError("Invalid resolution \(optres): hd, fhd, 2k and 4k")
            }
            
        case OptionCode.S.rawValue:
            let optres = String(cString: optarg)
            sharePaths = optres
                .split(separator: ",")
                .map({ (substring) in
                    return addTailingSlash(path: String(substring))
                })
            
            
            
        case OptionCode.h.rawValue:
            
            print("""
                Options available:
                 --cpu, -c: number of cpus [1..\(ProcessInfo.processInfo.processorCount - 1)]
                 --disk, -d: disk image size in GB
                 --mem, -m: memory size in GB
                 --iso, -i: Linux installer ISO path
                 --live, -l: Boot ISO in live mode only
                 --path, -p: bundle path with tailing slash eg. /path/to/Debian.bundle/
                 --raw-imgs, -R: additional disk image files seperate by comma
                 --resolution, -r: screen resolution preset [hd, fhd, 2k, 4k]
                 --share-paths, -s: share paths to guest seperate by comma
                 --help, -h: show this help
                 --version: show app version
                """)
            exit(0)
            
        case OptionCode.version.rawValue:
            
            print("\(appName!) \(appVersion!).\(buildVersion!)")
            exit(0)
            
        default:
            print("")
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, VZVirtualMachineDelegate {
    
    @IBOutlet var window: NSWindow!
    
    @IBOutlet weak var virtualMachineView: VZVirtualMachineView!
    
    private var virtualMachine: VZVirtualMachine!
    
    private var installerISOPath: URL?
    
    private var needsInstall = true
    
    override init() {
        super.init()
    }
    
    
    private func showDialog(title: String, text: String) -> Bool {
        
        
        let alert = NSAlert()
        
        alert.messageText = title
        alert.informativeText = text
        alert.window.level = .floating
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
        
    }
    
    private func createVMBundle() {
        
        do {
            try FileManager.default.createDirectory(atPath: vmBundlePath, withIntermediateDirectories: true)
        } catch {
            fatalError("Failed to create “LinuxVM.bundle.”")
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
    
    private func createNDBlockDeviceConfiguration(img: String) -> VZVirtioBlockDeviceConfiguration {
        guard let ndDiskAttachment = try? VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: img), readOnly: false) else {
            fatalError("Failed to attachment \(img).")
        }
        
        let ndDisk = VZVirtioBlockDeviceConfiguration(attachment: ndDiskAttachment)
        return ndDisk
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
    
#if arch(arm64)
    
    private func createRosettaShare()  ->  VZVirtioFileSystemDeviceConfiguration  {
        let tag = "ROSETTA"
        
        do {
            let _ =  try VZVirtioFileSystemDeviceConfiguration.validateTag(tag)
            let rosettaDirectoryShare = try VZLinuxRosettaDirectoryShare()
            let fileSystemDevice = VZVirtioFileSystemDeviceConfiguration(tag: tag)
            fileSystemDevice.share = rosettaDirectoryShare
            
            return fileSystemDevice
        } catch {
            fatalError("Rosetta is unavailable")
            
        }
        
    }
    
#endif
    
    private func createDirectoryShare(path: String)  ->  VZVirtioFileSystemDeviceConfiguration  {
        
        let tag = path
        let dir =  VZSharedDirectory(url: URL(fileURLWithPath: path), readOnly: false)
        
        do {
            let _ =  try VZVirtioFileSystemDeviceConfiguration.validateTag(tag)
            let DirectoryShare =   VZSingleDirectoryShare(directory:  dir)
            let fileSystemDevice = VZVirtioFileSystemDeviceConfiguration(tag: tag)
            fileSystemDevice.share = DirectoryShare
            
            
            return fileSystemDevice
        } catch {
            fatalError("Share Directory is unavailable")
            
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
        let shareFSArray = NSMutableArray()
        
        platform.machineIdentifier =  !FileManager.default.fileExists(atPath: machineIdentifierPath) ? createAndSaveMachineIdentifier() : retrieveMachineIdentifier()
        
        bootloader.variableStore = !FileManager.default.fileExists(atPath: efiVariableStorePath) ?
        createEFIVariableStore() : retrieveEFIVariableStore()
        
        if needsInstall {
            disksArray.add(createUSBMassStorageDeviceConfiguration())
        }
        
        virtualMachineConfiguration.platform = platform
        virtualMachineConfiguration.bootLoader = bootloader
        
        if !liveMode { disksArray.add(createBlockDeviceConfiguration())}
        
        if (ndDiskImagePath != nil) {
            print("Add image disks:")
            for path in ndDiskImagePath! {
                if FileManager.default.fileExists(atPath: path) {
                    disksArray.add(createNDBlockDeviceConfiguration(img: path))
                    print("\(path)")
                } else {
                    print("\(path) is not a file")
                }
                
            }
        }
        
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
        
#if arch(arm64)
        shareFSArray.add(createRosettaShare())
#endif
        var isDir : ObjCBool = true
        if (sharePaths != nil) {
            print("Use:")
            for path in sharePaths! {
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
                    shareFSArray.add(createDirectoryShare(path: path))
                    print("mount -t virtiofs \(path) mount_point")
                } else {
                    print("\(path) is not a directory")
                }
                
            }
        }
        
        
        virtualMachineConfiguration.directorySharingDevices = (shareFSArray as? [VZDirectorySharingDeviceConfiguration])!
        
        /*
         do {
         try createRosettaShare(configuration: virtualMachineConfiguration)
         } catch {
         print("Rosetta is unavailable\n")
         }
         */
        
        try! virtualMachineConfiguration.validate()
        virtualMachine = VZVirtualMachine(configuration: virtualMachineConfiguration)
    }
    
    // MARK: Start the virtual machine.
    
    func configureAndStartVirtualMachine() {
        window.title = String(NSString(string: vmBundlePath).lastPathComponent.split(separator: ".")[0])
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
        
        if CommandLine.argc < 2 && !FileManager.default.fileExists(atPath: vmBundlePath) {
            let x = showDialog(title: "Information", text: """
            \(appName!) \(appVersion!).\(buildVersion!)
            
            Now You can run this app.

            If you want to install Linux into default path click OK.

            For more information run:

            \(CommandLine.arguments[0]) --help

            """)
            if !x {
                exit(0)
            }
            
        }
        
        getOpt()
        
        NSApp.activate(ignoringOtherApps: true)
        
        if liveMode && isoPath != nil {
            
            print("Live Mode!!")
            needsInstall = true
            vmBundlePath = "/tmp/RunLinuxVM.bundle/"
            createVMBundle()
            
            self.installerISOPath =  URL(fileURLWithPath: isoPath!)
            
            self.configureAndStartVirtualMachine()
            
        } else if !FileManager.default.fileExists(atPath: vmBundlePath) {
            needsInstall = true
            createVMBundle()
            createMainDiskImage()
            
            if isoPath == nil {
                let openPanel = NSOpenPanel()
                openPanel.title = "Choose an ISO file"
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
                self.installerISOPath =  URL(fileURLWithPath: isoPath!)
                self.configureAndStartVirtualMachine()
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


