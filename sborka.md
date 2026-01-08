# Base components
| Component | Name |
| --------- | ---- |
| OS | Voidlinux |
| Libc | Glibc |
| Kernel | default (Linux) |
| Bootloader | Limine |
| Encryption | Luks |
| Fs | Btrfs & fat32 | 
| Init | Runit |
| Logging | Socklog |

# Desktop components
| Component | Name |
| --------- | --------- |
| User Services | Turnstile |
| Session/Seat managment | Dbus+Seatd+Turnstile |
| WC / WM | Niri |
| QT and GTK | no? |
| xdg desktop portal | Xdg desktop portal termfilechooser |
| Multimedia | Pipewire |
| Bluetooth | bluez |
| OpenPGP | GnuPG |

# Specific t480 components
| Component | Packages |
| --------- | -------- |
| Intel | linux-firmware-intel |
| OpenGL | mesa-dri |
| Vulkan | vulkan-loader mesa-vulkan-intel |
| Video acceleration | intel-video-accel |
