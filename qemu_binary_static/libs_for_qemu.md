# Get libraries for executing binaries with QEMU

## X86

On the X86 host run:

```
$ tar czf lib__linux-i386.tgz --transform="s,^/,," /lib/ld-linux*.so.* /lib/i386-linux-gnu
```

Extract the libraries on the AMD64 host:

```
$ mkdir -p /etc/qemu-binfmt/i386
$ tar xf lib__linux-i386.tgz -C /etc/qemu-binfmt/i386/
```

Run some binary on the AMD64 host:

```
$ qemu-i386-static ./i386-binary

Or with a specific CPU:
	Get list of emulatable CPUs:
		$ qemu-i386-static -cpu help
	Specify a CPU:
		$ qemu-i386-static -cpu n270 ./i386-binary
```

## AARCH64

On the AARCH64 host run:

```
$ tar czf lib__linux-aarch64.tgz --transform="s,^/,," /lib/ld-linux*.so.* /lib/aarch64-linux-gnu
```

Extract the libraries on the AMD64 host:

```
$ mkdir -p /etc/qemu-binfmt/aarch64
$ tar xf lib__linux-aarch64.tgz -C /etc/qemu-binfmt/aarch64/
```

Run some binary on the AMD64 host:

```
$ qemu-aarch64-static -L /etc/qemu-binfmt/aarch64 ./aarch64-binary

Or with a specific CPU:
	Get list of emulatable CPUs:
		$ qemu-aarch64-static -cpu help
	Specify a CPU:
		$ qemu-aarch64-static -cpu cortex-a57 -L /etc/qemu-binfmt/aarch64 ./aarch64-binary
```

## ARMv7l

On the ARMv7l host run:

```
$ tar czf lib__linux-armhf.tgz --transform="s,^/,," /lib/ld-linux*.so.* /lib/arm-linux-gnueabihf
```

Extract the libraries on the AMD64 host:

```
$ mkdir -p /etc/qemu-binfmt/armhf
$ tar xf lib__linux-armhf.tgz -C /etc/qemu-binfmt/armhf/
```

Run some binary on the AMD64 host:

```
$ qemu-arm-static -L /etc/qemu-binfmt/armhf ./armhf-binary

Or with a specific CPU:
	Get list of emulatable CPUs:
		$ qemu-arm-static -cpu help
	Specify a CPU:
		$ qemu-arm-static -cpu cortex-a9 -L /etc/qemu-binfmt/armhf ./armhf-binary
```
