# ❄️ My Minimal Hyprland Dotfiles

Welcome to my personal dotfiles repository! This setup is focused on a clean, minimal, and highly performant Wayland environment on Arch Linux, featuring a custom glassmorphism UI.

## 🖼️ Preview
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bca770ca-3ac1-4773-bf74-5ed628c3375d" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b0e977d0-0c33-4f69-bf0f-79ce0635470c" />
<img width="1919" height="1080" alt="image" src="https://github.com/user-attachments/assets/2184f7f2-a727-4d85-a509-957c628f51a3" />
<img width="349" height="661" alt="image" src="https://github.com/user-attachments/assets/5b089b9d-f0bb-4794-b17f-5fb42be17f49" />





## 🚀 Tech Stack & Dependencies

Here is the core stack used in this configuration:

* **OS:** Arch Linux
* **Window Manager:** [Hyprland](https://hyprland.org/)
* **Terminal Emulator:** `kitty`
* **Shell:** `fish`
* **Text Editor:** `neovim` (Powered by LazyVim)
* **App Launcher:** `rofi-wayland` (Custom glassmorphism theme)
* **Browser:** `zen-browser-bin`
* **Notification Daemon:** `swaync`
* **Screenshot Utilities:** `grim` + `slurp` + `wl-clipboard`
* **Dotfile Management:** `stow`
* **Fonts:** `ttf-jetbrains-mono-nerd`

## ⚙️ Installation Guide (outdated)

If you (or future me) want to replicate this setup on a fresh Arch Linux install, follow these steps:

**1. Install AUR Helper (yay)**
Ensure you have `git` and `base-devel` installed, then clone and build `yay`:
```bash
git clone [https://aur.archlinux.org/yay.git](https://aur.archlinux.org/yay.git)
cd yay
makepkg -si
```

**2. Install Required Packages**
Use `yay` to install all the core tools and dependencies:
```bash
yay -S hyprland kitty fish neovim rofi-wayland swaync grim slurp wl-clipboard zen-browser-bin stow ttf-jetbrains-mono-nerd
```

**3. Clone & Apply Dotfiles**
Clone this repository into your home directory and use GNU Stow to create the necessary symlinks:
```bash
git clone [https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git](https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git) ~/dotfiles
cd ~/dotfiles
stow .
```
*(Make sure to replace `YOUR_GITHUB_USERNAME` with your actual username).*

## ⌨️ Essential Keybinds

Here are the quick shortcuts configured in this setup:

| Action | Shortcut |
| :--- | :--- |
| **App Launcher (Rofi)** | `Super` (Press and Release) |
| **Terminal (Kitty)** | `Super + T` |
| **Web Browser (Zen)** | `Super + B` |
| **Screenshot (Area -> Clipboard & Save)** | `Super + Shift + S` |
| **Change Language (US/TH)** | `Alt + Shift` *(Changeable in config)* |

---
*Stay highly productive and keep ricing!*
