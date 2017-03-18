### LDD3 CHAPTER 3 

### Char Drivers 

Throughout the chapter, we present code fragments extracted from a real device driver: scull (Simple Character Utility for Loading Localities). scull is a char driver that acts on a memory area as though it were a device. In this chapter, because of that peculiarity of scull, we use the word device interchangeably with “the memory area used by scull. 

### The Design of scull 

To make scull useful as a template for writing real drivers for real devices, we’ll show you how to implement several device abstractions on top of the computer memory, each with a different personality. 

```
scull0 to scull3 
Four devices, each consisting of a memory area that is both global and persistent. 
./scull/scull.h:48:#define SCULL_NR_DEVS 4    /* scull0 through scull3 */

scullpipe0 to scullpipe3 
./scull/scull.h:52:#define SCULL_P_NR_DEVS 4  /* scullpipe0 through scullpipe3 */

scullsingle scullpriv sculluid scullwuid 
./scull/access.c:332:	{ "scullsingle", &scull_s_device, &scull_sngl_fops },
./scull/scull.h:92:	unsigned int access_key;  /* used by sculluid and scullpriv */
./scull/access.c:333:	{ "sculluid", &scull_u_device, &scull_user_fops },
./scull/scull.h:92:	unsigned int access_key;  /* used by sculluid and scullpriv */
./scull/access.c:334:	{ "scullwuid", &scull_w_device, &scull_wusr_fops },
```

This chapter covers the internals of scull0 to scull3; 
the more advanced devices are covered in Chapter 6. scullpipe is described in the section “A Blocking I/O Example,” and the others are described in “Access Control on a Device File.”

### Major and Minor Numbers 

Special files for char drivers are identified by a “c” in the first column of the output of ls –l. Block devices appear in /dev as well, but they are identified by a “b.” 


￼
Modern Linux kernels allow multiple drivers to share major numbers, but most devices that you will see are still organized on the one-major-one-driver principle. 

The minor number is used by the kernel to determine exactly which device is being referred to. 


### The Internal Representation of Device Numbers 

Within the kernel, the dev_t type (defined in <linux/types.h>) is used to hold device numbers—both the major and minor parts. 

make use of a set of macros found in <linux/kdev_t.h>. To obtain the major or minor parts of a dev_t, use: 
     MAJOR(dev_t dev);
     MINOR(dev_t dev);
If, instead, you have the major and minor numbers and need to turn them into a dev_t, use: 
     MKDEV(int major, int minor);

2.6 kernel can accommodate a vast number of devices, while previous kernel versions were limited to 255 major and 255 minor numbers. 
So you should expect that the format of dev_t could change again in the future; if you write your drivers carefully, however, these changes will not be a problem. 

### Allocating and Freeing Device Numbers 

to obtain one or more device numbers to work with, use register_chrdev_region, which is declared in <linux/fs.h>: 

The kernel will happily allocate a major number for you on the fly, but you must request this allocation by using a different function: 
     int alloc_chrdev_region(dev_t *dev, unsigned int firstminor,
                             unsigned int count, char *name);

Device numbers are freed with: 
     void unregister_chrdev_region(dev_t first, unsigned int count);

### Dynamic Allocation of Major Numbers 

Thus, for new drivers, we strongly suggest that you use dynamic allocation to obtain your major device number, rather than choosing a number randomly from the ones that are currently free. 

once the number has been assigned, you can read it from /proc/devices.* 

To load a driver using a dynamic major number, therefore, the invocation of insmod can be replaced by a simple script that, after calling insmod, reads /proc/devices in order to create the special file(s). 
A typical /proc/devices file looks like the following: 

```
Character devices:
      1 mem
      2 pty
      3 ttyp
      4 ttyS
      6 lp
      7 vcs
      10 misc
      13 input
      14 sound
Block devices:
      2 fd
      8 sd
      11 sr
      65 sd
      66 sd
```

Even better device information can usually be obtained from sysfs, generally mounted on /sys on 2.6-based systems. Getting scull to export information via sysfs is beyond the scope of this chapter, however; we’ll return to this topic in Chapter 14. 

The following script, scull_load, is part of the scull distribution:

```
#!/bin/sh
     module="scull"
     device="scull"
     mode="664"
     # invoke insmod with all arguments we got
     # and use a pathname, as newer modutils don't look in . by default
     /sbin/insmod ./$module.ko $* || exit 1
     # remove stale nodes
     rm -f /dev/${device}[0-3]
major=$(awk "\\$2==\"$module\" {print \\$1}" /proc/devices) 
     mknod /dev/${device}0 c $major 0
     mknod /dev/${device}1 c $major 1
     mknod /dev/${device}2 c $major 2
     mknod /dev/${device}3 c $major 3
     # give appropriate group/permissions, and change the group.
     # Not all distributions have staff, some have "wheel" instead.
     group="staff"
     grep -q '^staff:' /etc/group || group="wheel"
     chgrp $group /dev/${device}[0-3]
     chmod $mode  /dev/${device}[0-3]
```

As an alternative to using a pair of scripts for loading and unloading, you could write an init script, ready to be placed in the directory your distribution uses for these scripts.* As part of the scull source, we offer a fairly complete and configurable exam- ple of an init script, called scull.init; it accepts the conventional arguments—start, stop, and restart—and performs the role of both scull_load and scull_unload. 

### Some Important Data Structures 

Most of the fundamental driver opera- tions involve three important kernel data structures, called file_operations, file, and inode. 

### File Operations 

The scull device driver implements only the most important device methods. Its file_operations structure is initialized as follows: 

```
struct file_operations scull_fops = {
.owner =
.llseek =
.read =
.write =
.ioctl =
.open =
.release =  scull_release,
THIS_MODULE,
scull_llseek,
scull_read,
scull_write,
scull_ioctl,
scull_open,
}; 
```

### The file Structure 

The file structure represents an open file. (It is not specific to device drivers; every open file in the system has an associated struct file in kernel space.) It is created by the kernel on open and is passed to any function that operates on the file, until the last close. After all instances of the file are closed, the kernel releases the data structure. 

### The inode Structure 
The inode structure is used by the kernel internally to represent files. Therefore, it is different from the file structure that represents an open file descriptor. There can be numerous file structures representing multiple open descriptors on a single file, but they all point to a single inode structure. 

### Char Device Registration 
As we mentioned, the kernel uses structures of type struct cdev to represent char devices internally. Before the kernel invokes your device’s operations, you must allo- cate and register one or more of these structures.* 

### Device Registration in scull 
Internally, scull represents each device with a structure of type struct scull_dev. This structure is defined as: 

```
struct scull_dev {
        struct scull_qset *data;  /* Pointer to first quantum set */
        int quantum;
        int qset;
        unsigned long size;
        unsigned int access_key;  /* used by sculluid and scullpriv */
        struct semaphore sem;     /* mutual exclusion semaphore     */
        struct cdev cdev;     /* Char device structure      */
}; 
```

We discuss the various fields in this structure as we come to them, but for now, we call attention to cdev, the struct cdev that interfaces our device to the kernel. This 
structure must be initialized and added to the system as described above; the scull code that handles this task is: 

```
static void scull_setup_cdev(struct scull_dev *dev, int index)
{
         int err, devno = MKDEV(scull_major, scull_minor + index);
         cdev_init(&dev->cdev, &scull_fops);
         dev->cdev.owner = THIS_MODULE;
         dev->cdev.ops = &scull_fops;
         err = cdev_add (&dev->cdev, devno, 1);
         /* Fail gracefully if need be */
if (err) 
         printk(KERN_NOTICE "Error %d adding scull%d", err, index);
}
```

