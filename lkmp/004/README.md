Honestly, who loads or even cares about proprietary modules? If you do then you might have seen something like this:

# insmod xxxxxx.o
Warning: loading xxxxxx.ko will taint the kernel: no license
  See http://www.tux.org/lkml/#export-tainted for information about tainted modules
Module xxxxxx loaded, with warnings
You can use a few macros to indicate the license for your module. Some examples are "GPL", "GPL v2", "GPL and additional rights", "Dual BSD/GPL", "Dual MIT/GPL", "Dual MPL/GPL" and "Proprietary". They're defined within linux/module.h.

To reference what license you're using a macro is available called MODULE_LICENSE. This and a few other macros describing the module are illustrated in the below example.
