#!/bin/bash

# Script de instalación de Qtile, Hyprland y SDDM en Arch Linux
# Ejecutar con privilegios de superusuario

set -e  # Detener el script si ocurre algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    exit 1
fi

# Actualizar el sistema
print_status "Actualizando el sistema..."
pacman -Syu --noconfirm

# Instalar dependencias básicas
print_status "Instalando dependencias básicas..."
pacman -S --noconfirm --needed \
    base-devel \
    git \
    python \
    python-pip \
    python-setuptools \
    python-wheel \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xsetroot \
    xorg-xprop \
    libxcb \
    xcb-util \
    xcb-util-keysyms \
    xcb-util-wm \
    xcb-util-cursor \
    xcb-util-xrm \
    pango \
    cairo \
    gdk-pixbuf2 \
    glib2 \
    gtk3 \
    polkit \
    dbus \
    networkmanager \
    pulseaudio \
    pulseaudio-alsa \
    alsa-utils

# Instalar Qtile
print_status "Instalando Qtile..."
pacman -S --noconfirm --needed \
    qtile \
    python-dbus-next \
    python-psutil \
    python-xlib

# Instalar Hyprland
print_status "Instalando Hyprland..."
pacman -S --noconfirm --needed \
    hyprland \
    waybar \
    rofi \
    wofi \
    kitty \
    foot \
    swaybg \
    swaylock \
    grim \
    slurp \
    wl-clipboard

# Instalar SDDM
print_status "Instalando SDDM..."
pacman -S --noconfirm --needed \
    sddm \
    qt5-quickcontrols2 \
    qt5-graphicaleffects

# Habilitar servicios
print_status "Habilitando servicios..."
systemctl enable sddm
systemctl enable NetworkManager

# Configuración básica de SDDM
print_status "Configurando SDDM..."
cat > /etc/sddm.conf << EOF
[Theme]
Current=breeze

[Autologin]
Session=hyprland.desktop

[X11]
ServerPath=/usr/bin/X
EOF

# Crear directorios de configuración si no existen
mkdir -p /etc/skel/.config/qtile/
mkdir -p /etc/skel/.config/hypr/
mkdir -p /etc/skel/.config/waybar/

# Configuración básica de Qtile
print_status "Creando configuración básica de Qtile..."
cat > /etc/skel/.config/qtile/config.py << 'EOF'
from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
import os
import subprocess

mod = "mod4"
terminal = guess_terminal()

keys = [
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen(),
            desc="Switch to group {}".format(i.name)),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True),
            desc="Switch to & move focused window to group {}".format(i.name)),
    ])

layouts = [
    layout.Columns(border_focus_stack=['#d75f5f', '#8f3d3d'], border_width=4),
    layout.Max(),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font='sans',
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        bottom=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        'launch': ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                widget.Systray(),
                widget.Clock(format='%Y-%m-%d %a %I:%M %p'),
                widget.QuickExit(),
            ],
            24,
        ),
    ),
]

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class='confirmreset'),
        Match(wm_class='makebranch'),
        Match(wm_class='maketag'),
        Match(wm_class='ssh-askpass'),
        Match(title='branchdialog'),
        Match(title='pinentry'),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

auto_minimize = True

wmname = "LG3D"
EOF

# Configuración básica de Hyprland
print_status "Creando configuración básica de Hyprland..."
cat > /etc/skel/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration

monitor=,preferred,auto,auto

exec-once = waybar & swaybg -i ~/wallpaper.jpg

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
}

general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur = yes
    blur_size = 3
    blur_passes = 1
    blur_new_optimizations = on
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = on
}

device:epic-mouse-v1 {
    sensitivity = -0.5
}

$mainMod = SUPER

bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF

# Configuración básica de Waybar
print_status "Creando configuración básica de Waybar..."
mkdir -p /etc/skel/.config/waybar/
cat > /etc/skel/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "clock", "tray"],
    
    "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate"
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "{:%A, %B %d, %Y}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "🔇",
        "format-icons": ["🔈", "🔉", "🔊"],
        "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%)",
        "format-ethernet": "Ethernet",
        "format-disconnected": "Disconnected",
        "tooltip-format": "{ifname} via {gwaddr}"
    },
    
    "cpu": {
        "format": "CPU {usage}%"
    },
    
    "memory": {
        "format": "RAM {}%"
    }
}
EOF

cat > /etc/skel/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "Fira Code", "Font Awesome 5 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: #2e3440;
    color: #d8dee9;
}

#workspaces button {
    padding: 0 5px;
    background: transparent;
    color: #d8dee9;
    border-bottom: 3px solid transparent;
}

#workspaces button.focused {
    background: #434c5e;
    border-bottom: 3px solid #88c0d0;
}

#clock, #pulseaudio, #network, #cpu, #memory {
    padding: 0 10px;
    margin: 0 5px;
}

#clock {
    background-color: #5e81ac;
}

#pulseaudio {
    background-color: #a3be8c;
}

#network {
    background-color: #b48ead;
}

#cpu {
    background-color: #d08770;
}

#memory {
    background-color: #ebcb8b;
}
EOF

# Crear enlaces simbólicos para las sesiones de SDDM
print_status "Configurando sesiones para SDDM..."
mkdir -p /usr/share/xsessions/
cat > /usr/share/xsessions/qtile.desktop << 'EOF'
[Desktop Entry]
Name=Qtile
Comment=Qtile Session
Exec=qtile start
Type=Application
EOF

mkdir -p /usr/share/wayland-sessions/
cat > /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Session
Exec=Hyprland
Type=Application
EOF

# Mensaje final
print_success "Instalación completada!"
print_warning "Recomendaciones:"
echo "1. Reinicia el sistema: reboot"
echo "2. En SDDM, selecciona Qtile (X11) o Hyprland (Wayland)"
echo "3. Las configuraciones se encuentran en ~/.config/"
echo "4. Personaliza los archivos de configuración según tus necesidades"

print_success "Qtile, Hyprland y SDDM han sido instalados correctamente!"
