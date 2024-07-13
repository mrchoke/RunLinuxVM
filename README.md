[ภาษาไทย](#running-gui-linux-in-a-virtual-machine-on-a-mac---thai)
---

# Running GUI Linux in a Virtual Machine on a Mac - English

Install and run GUI Linux in a virtual machine using the Virtualization framework.

## Building and Usage

** Set Developer Profile and Sign the package**

## Support for Intel & Apple Silicon

Starting from Version 1.1, the app is Universal and can be used on both Intel and M1, M2.

## First-time Usage after Installation

Since the app is not in the App Store, enable the option to run from the App Store and trusted developers:

```
System Setting --> Privacy & Security --> Security --> App Store and identified developers
```

Then, open the app by right-clicking and selecting Open.

If you can run it, a dialog will appear. If you want to install the first Linux in the default path, click OK. Otherwise, cancel and use the command line as shown below.

## Added Options

```console
$ /Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM --help
Options available:
 --cpu, -c: number of CPUs [1..9]
 --disk, -d: disk image size in GB
 --mem, -m: memory size in GB
 --iso, -i: Linux installer ISO path
 --live, -l: Boot ISO in live mode only
 --path, -p: bundle path with trailing slash e.g., /path/to/Debian.bundle/
 --raw-imgs, -I: additional disk image files separated by commas
 --resolution, -r: screen resolution preset [hd, fhd, 2k, 4k]
 --share-paths, -s: share paths to guest separated by commas
 --help, -h: show this help
 --version: show app version
```

## Running the VM

If you click run directly, it will use the path specified in the code, which is `$HOME/LinuxVM.bundle`. If you close the dialog or the installation fails, you must delete that path before running it again.

### Example of Running with Specified Options

The first run will be the installation; you need to have the ISO ready and specify the option -d or --disk for the image size in GB. For subsequent runs, you don't need to specify the disk size.

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
 --path $HOME/LinuxVM/Ubuntu.bundle/ \
 --resolution hd  \
 --cpu 4 \
 --mem 4 \
 --disk 10
```

After installation, you can change various settings as desired or according to your machine's capabilities.

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
 --path $HOME/LinuxVM/Ubuntu.bundle/ \
 --resolution 4k \
 -cpu 4 \
 -mem 4 
```

### Live Mode

If you only want to play from the ISO without installing, specify the iso and live options as follows:

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
--live \
--iso Ubuntu-22.10.iso
```

Currently, there are few distros with arm64 ISOs, but if you use an Intel CPU, you can run many distros.

### Sharing Directory from macOS

You can share a directory from macOS to the Linux guest by specifying the option. If there is more than one directory, separate them with commas, like this:

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
--path $HOME/LinuxVM/Debian.bundle/ \
--share-paths "$HOME,/Volumes/SSD/"
```

If the directories exist, the app will share them. When you boot into Linux, mount them with the command:

```console
$ sudo mount -t virtiofs /User/mrchoke/ /mnt/mac_home
$ sudo mount -t virtiofs /Volumes/SSD/ /mnt/mac_ssd
```

The tag specified will be the full macOS path.

### Adding Additional Disk Images

If you want to add disk images or raw disk images with the `.img` extension, such as Linux images from various distributions, you can add them. If there is more than one image, separate them with commas, like this:

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
--path $HOME/LinuxVM/Debian.bundle/ \
--raw-imgs "$HOME/LinuxVM/Ubuntu.bundle/Disk.img,$HOME/Downloads/Manjaro-ARM.img"
```

If these images exist, after booting into Linux, you can mount or format them to perform a chroot installation. Check with the command:

```console
$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
vda    254:0    0   64G  0 disk 
- vda1 254:1    0  512M  0 part /boot/efi
- vda2 254:2    0 62.5G  0 part /
- vda3 254:3    0  976M  0 part [SWAP]
vdb    254:16   0   10G  0 disk 
- vdb1 254:17   0  300M  0 part 
- vdb2 254:18   0  9.7G  0 part 
vdc    254:32   0   15G  0 disk 
- vdc1 254:33   0  128M  0 part 
- vdc2 254:34   0 14.9G  0 part
```

Or use `fdisk -l`, where you'll see additional disks such as `/dev/vdb`, `/dev/vdc`, etc., alongside `/dev/vda`.

### Running Intel Binaries in Linux VMs with Rosetta

This feature is only available on M1 or M2 machines. It's not needed on Intel since it’s already x86_64. I've added code from Apple's example, and you can try it as follows:

Tag is named `ROSETTA`.

```console
% mkdir /tmp/mountpoint
% sudo mount -t virtiofs ROSETTA /tmp/mountpoint
% ls /tmp/mountpoint rosetta
% sudo /usr/sbin/update-binfmts --install rosetta /tmp/mountpoint/rosetta \
    --magic "\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00" \
    --mask "\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff" \
    --credentials yes --preserve no --fix-binary yes
```

For Linux with the `update-binfmts` command, like Ubuntu and Debian, install additional packages first:

```console
% apt install binfmt-support
```

### Other Features

- Copy/Paste between Host and Guest is supported. You can also switch between Guest and Guest or between your other devices logged in with the same Apple ID.

### Possible Issues

- Some distros may lack sound because the kernel doesn't support `virtio_snd`, but you can compile the kernel yourself, such as with Debian 11.
- Copy/Paste functionality: Most distros come with `spice-vdagent`, but some may require you to install it yourself.

[English](#running-gui-linux-in-a-virtual-machine-on-a-mac---english) 
# ภาษาไทย

# Running GUI Linux in a virtual machine on a Mac - Thai

Install and run GUI Linux in a virtual machine using the Virtualization framework.

## การ build และใช้งาน

** __ให้เรากำหนด Developer Profile และ Signing package__

## Support Intel & Apple Silicon

ตั้งแต่ Version 1.1 เป็นต้นไป App จะเป็น Universal สามารถใช้ได้ทั้ง Intel และ M1, M2

## การใช้งานครั้งแรกหลังจากติดตั้ง App 

เนื่องจาก App ไม่ได้อยู่ใน App Store ให้ท่านเปิด option การรันจาก App Store และ นักพัฒนาที่เชื่อถือได้

```
System Setting --> Privacy Security --> Security --> App Store amd identified developer
```
หลังจากนั้นให้เปิด App ด้วยการ `Click ขวา และเลือก Open`

ถ้าหากท่านสามารถใช้งานได้จะมี Dialog ขึ้นมาหากต้องการติดตั้ง Linux ตัวแรกใน default path ก็ให้ Click OK ได้เลย แต่ถ้าหากต้องการใช้ command line ให้  Cancel แล้วสั่งคำสั่งจากตั้วอย่างด้านล่าง

## Options ที่เพิ่มเข้าไป

```console
$ /Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM --help
Options available:
 --cpu, -c: number of cpus [1..9]
 --disk, -d: disk image size in GB
 --mem, -m: memory size in GB
 --iso, -i: Linux installer ISO path
 --live, -l: Boot ISO in live mode only
 --path, -p: bundle path with tailing slash eg. /path/to/Debian.bundle/
 --raw-imgs, -I: additional disk image files seperate by comma
 --resolution, -r: screen resolution preset [hd, fhd, 2k, 4k]
 --share-paths, -s: share paths to guest seperate by comma
 --help, -h: show this help
 --version: show app version

```
## การ run VM

ถ้า click run app โดยตรงจะใช้ path ที่กำหนดไว้ใน code คือ `$HOME/LinuxVM.bundle` ถ้าเราปิด dialog ทิ้งหรือติดตั้งไม่สำเร็จต้องลบ path นั้นทิ้งก่อน ถึงจะ run ครั้งต่อไปได้

### ตัวอย่างการ run แบบระบุ options

การ run ครั้งแรกจะเป็นการติดตั้งเราต้องเตรียม ISO ไว้ให้เรียบร้อย และ ระบุ option -d หรือ --disk เป็นขนาดของ image หน่วยเป็น GB ถ้า run ครั้งต่อไปก็ไม่จำเป็นต้องระบุขนาด disk

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
 --path $HOME/LinuxVM/Ubuntu.bundle/ \
 --resolution hd  \
 --cpu 4 \
 --mem 4 \
 --disk 10

```

การ run หลังจากติดตั้งเสร็จเราสามารถเปลี่ยนค่าต่าง ๆ ได้ตามใจชอบหรือตามความสามารถของเครื่องนะครับ

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
 --path $HOME/LinuxVM/Ubuntu.bundle/ \
 --resolution 4k \
 -cpu 4 \
 -mem 4 

```

### Live Mode

ในกรณีที่ท่านไม่อยากติดตั้งแค่อยากจะเล่นจาก ISO อย่างเดียวสามารถระบุ iso และ live ดังนี้

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
--live \
--iso Ubuntu-22.10.iso
```
แต่ปัจจุบัน Distro ที่มี iso arm64 ยังน้อย แต่ถ้าท่านใช้ CPU Intel สามารถ run ได้หลาย Distro

### Share directory from macOS

ท่านสามารถ Share directory จาก macOS ไปยัง Linux Guest ได้ โดยการระบุ option ถ้าหากมีมากกว่าหนึ่ง directory ให้ใช้ comma คั่นเช่น

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
--path $HOME/LinuxVM/Debian.bundle/ \
--share-paths "$HOME,/Volums/SSD/"
```
ถ้า directory มีอยู่จริง app จะทำการ share ให้เมื่อท่าน boot เข้าไปยัง Linux ให้ mount โดยใช้คำสั่ง

```console
$ sudo mount -t virtiofs /User/mrchoke/ /mnt/mac_home
$ sudo mount -t virtiofs /Volums/SSD/ /mnt/mac_ssd
```
โดย Tag ที่ระบุจะเป็น path เต็มของ macOS 

### การ add disk image เพิ่มเติม

ในกรณีที่ท่านต้องการเพิ่ม disk image หรือ raw disk image ที่มีนามสกุล `.img` เช่น linux image จากค่ายต่าง ๆ  image ของ VM ที่ถูกสร้างจาก App นี้สามารถเพิ่มเข้าไปได้ทั้งหมดถ้ามากกว่าหนึ่ง image ให้ใช้ comma คั่น เช่น

```console
/Applications/RunLinuxVM.app/Contents/MacOS/RunLinuxVM  \
--path $HOME/LinuxVM/Debian.bundle/ \
--raw-imgs "$HOME/LinuxVM/Ubuntu.bundle/Disk.img,$HOME/Downloads/Manjaro-ARM.img"
```
ถ้า image เหล่านั้นมีอยู่จริง เมื่อ boot เข้าไปยัง Linux เสร็จแล้วสามารถ mount ใช้งาน หรือ format เพื่อทำการติดตั้งแบบ chroot ได้ โดยสามารถตรวจสอบด้วยคำสั่ง

```console
$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
vda    254:0    0   64G  0 disk 
- vda1 254:1    0  512M  0 part /boot/efi
- vda2 254:2    0 62.5G  0 part /
- vda3 254:3    0  976M  0 part [SWAP]
vdb    254:16   0   10G  0 disk 
- vdb1 254:17   0  300M  0 part 
- vdb2 254:18   0  9.7G  0 part 
vdc    254:32   0   15G  0 disk 
- vdc1 254:33   0  128M  0 part 
- vdc2 254:34   0 14.9G  0 part
```

หรือจะ `fdisk -l` ก็ได้ ซึ่งจะเห็น disk เพิ่มเติมเข้ามาจากเดิมจะมีแค่ `/dev/vda` ก็จะมี `/dev/vdb /dev/vdc ...`

### Running Intel Binaries in Linux VMs with Rosetta

Feature นี้จะใช้ได้เฉพาะ เครื่อง M1 หรือ M2 เท่านั้นบน Intel ไม่จำเป็นเพราะเป็น x86_64 อยู่แล้ว
ผมได้เพิ่ม code จากตัวอย่างของ  apple ไว้แล้วสามารถทดลองใช้ได้เลยโดยมีวิธีการดังนี้

Tag ผมใช้คำว่่า `ROSETTA` 

```console
% mkdir /tmp/mountpoint
% sudo mount -t virtiofs ROSETTA /tmp/mountpoint
% ls /tmp/mountpoint rosetta
% sudo /usr/sbin/update-binfmts --install rosetta /tmp/mountpoint/rosetta \
    --magic "\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00" \
    --mask "\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff" \
    --credentials yes --preserve no --fix-binary yes

```

Linux ที่มีคำสั่ง `update-binfmts` เช่น Ubuntu และ Debian ให้ลงเพิ่มเติมก่อน

```console
% apt install binfmt-support
```

### Features อื่น ๆ

-  Copy / Paste ระหว่าง Host กับ Guest ได้ และ สามารถข้ามไปมาระหว่าง Guest กับ Guest ก็ได้ หรือระหว่า อุปกรณ์อื่น ๆ ของท่านที่ login ด้วย Apple ID เดียวกัน 


### สิ่งที่อาจจะเกิดขึ้นได้

- บาง Distro จะไม่มีเสียงเพราะ kernel ไม่ support virtio_snd แต่สามารถ compile kernel ใหม่ได้เช่น Debian 11 เป็นต้น
- Copy / Paste Distro ส่วนใหญ่จะมี spice-vdagent มาให้แต่ก็มีบาง Distro ท่านอาจจะต้องติดตั้งเองถึงจะได้ใช้งานได้

---
## Overview

This sample code project demonstrates how to install and run GUI Linux virtual machines (VMs) on a Mac.

The Xcode project includes a single target, `GUILinuxVirtualMachineSampleApp`, which is a macOS app that installs a Linux distribution from an ISO image into a VM, and subsequently runs the installed Linux VM.

[class_VZVirtualMachineConfiguration]:https://developer.apple.com/documentation/virtualization/vzvirtualmachineconfiguration
[class_VZLinuxBootLoader]:https://developer.apple.com/documentation/virtualization/vzlinuxbootloader
[class_VZVirtualMachine]:https://developer.apple.com/documentation/virtualization/vzvirtualmachine
[property_bootLoader]:https://developer.apple.com/documentation/virtualization/vzvirtualmachineconfiguration/3656716-bootloader
[method_start]:https://developer.apple.com/documentation/virtualization/vzvirtualmachine/3656826-start
[method_guestDidStop]:https://developer.apple.com/documentation/virtualization/vzvirtualmachinedelegate/3656730-guestdidstop

## Download a Linux installation image 

Before you run the sample program, you need to download an ISO installation image from a Linux distribution website. Some common Linux distributions include:

- [Debian](https://www.debian.org/distrib/)
- [Fedora](https://getfedora.org/en/workstation/download/)
- [Ubuntu](https://ubuntu.com/download/desktop)


- Important: The Virtualization framework can run Linux VMs on a Mac with Apple silicon, and on an Intel-based Mac. The Linux ISO image you download must support the CPU architecture of your Mac. For a Mac with Apple silicon, download a Linux ISO image for ARM, which is usually indicated by `aarch64` or `arm64` in the image filename. For an Intel-based Mac, download a Linux ISO image for Intel-compatible CPUs, which is usually indicated by `x86_64` or `amd64` in the image filename.

- Note: If you need to run Intel Linux binaries in ARM Linux on a Mac with Apple silicon, the Virtualization framework supports this capability using the Rosetta translation environment. For more information, see [Running Intel Binaries in Linux VMs with Rosetta](https://developer.apple.com/documentation/virtualization/running_intel_binaries_in_linux_vms_with_rosetta).


## Configure the sample code project

1. Launch Xcode and open `GUILinuxVirtualMachineSampleApp.xcodeproj`.

2. Navigate to the Signing & Capabilities panel and select your team ID.

3. Build and run GUILinuxVirtualMachineSampleApp. The sample app starts the VM and configures a graphical view that you interact with. The Linux VM continues running until you shut it down from the guest OS, or when you quit the app.

    When you run the app for the first time, it displays a file picker so you can choose the Linux installation ISO image to use for installing your Linux VM. Navigate to the ISO image that you downloaded, select the file, and click Open. The VM boots into the OS installer, and the installer's user interface appears in the app's window. Follow the installation instructions. When the installation finishes, the Linux VM is ready to use.

     As part of the installation process, the Virtualization framework creates a `GUI Linux VM.bundle` package in your home directory. The sample app only supports running one VM at a time, however, the Virtualization framework supports running multiple VMs simultaneously. Running multiple VMs requires an app to manage the execution and artifacts of each individual VM.
    
    The contents of the bundle represent the state of the Linux guest, and contain the following:

    * `Disk.img` — The main disk image of the installed Linux OS.
    * `MachineIdentifier` — The data representation of the `VZGenericMachineIdentifier` object.
    * `NVRAM` — The EFI variable store.

    Subsequent launches of GUILinuxVirtualMachineSampleApp run the installed Linux VM. To reinstall the VM, delete the `GUI Linux VM.bundle` package and run the app again.


## Install GUI Linux from an ISO image

The sample app configures a `VZDiskImageStorageDeviceAttachment` object with the downloaded ISO image attached, and creates a `VZUSBMassStorageDeviceConfiguration` with it to emulate a USB thumb drive that's plugged in to the VM.

``` swift
private func createUSBMassStorageDeviceConfiguration() -> VZUSBMassStorageDeviceConfiguration {
    guard let intallerDiskAttachment = try? VZDiskImageStorageDeviceAttachment(url: installerISOPath!, readOnly: true) else {
        fatalError("Failed to create installer's disk attachment.")
    }

    return VZUSBMassStorageDeviceConfiguration(attachment: intallerDiskAttachment)
}
```


## Set up the VM

The sample app uses a [`VZVirtualMachineConfiguration`][class_VZVirtualMachineConfiguration] object to configure the basic characteristics of the VM, such as the CPU count, memory size, various device configurations, and a `VZEFIBootloader` to load the Linux operating system into the VM.

``` swift
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
virtualMachineConfiguration.consoleDevices = [createSpiceAgentConsoleDeviceConfiguration()]

try! virtualMachineConfiguration.validate()
virtualMachine = VZVirtualMachine(configuration: virtualMachineConfiguration)
```

## Enable copy-and-paste support between the host and the guest

In macOS 13 and later, the Virtualization framework supports copy-and-paste of text and images between the Mac host and Linux guests through the SPICE agent clipboard-sharing capability. The example below shows the steps for configuring `VZVirtioConsoleDeviceConfiguration` and `VZSpiceAgentPortAttachment` to enable this capability:
``` swift
private func createSpiceAgentConsoleDeviceConfiguration() -> VZVirtioConsoleDeviceConfiguration {
    let consoleDevice = VZVirtioConsoleDeviceConfiguration()

    let spiceAgentPort = VZVirtioConsolePortConfiguration()
    spiceAgentPort.name = VZSpiceAgentPortAttachment.spiceAgentPortName
    spiceAgentPort.attachment = VZSpiceAgentPortAttachment()
    consoleDevice.ports[0] = spiceAgentPort

    return consoleDevice
}
```

- Important: To use the copy-and-paste capability in Linux, the user needs to install the spice-vdagent package, which is available through most Linux package managers. Developers need to communicate this requirement to users of their apps.


## Start the VM

After building the configuration data for the VM, the sample app uses the `VZVirtualMachine` object to start the execution of the Linux guest operating system.

Before calling the VM's [`start`][method_start] method, the sample app configures a delegate object to receive messages about the state of the virtual machine. When the Linux operating system shuts down, the VM calls the delegate's [`guestDidStop`][method_guestDidStop] method. In response, the delegate method prints a message and exits the sample.

``` swift
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
```
