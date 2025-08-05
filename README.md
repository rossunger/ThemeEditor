# Theme Editor
A tool for editing godot themes. <br><br>
<img width="618" height="245" alt="image" src="https://github.com/user-attachments/assets/aa7437fb-26d2-435b-a901-12ee3a230dfd" />

### Features
- Color variables: define colors in one place (e.g. primary_color, accent_color). When you update them, every theme variation and stylebox that uses that color will be updated live. 
- Number variables: define numbers in one place (e.g. font_size_xl, corner_radius_round). When you update them, every theme variation that uses them will update live
- Font variables: define fonts in one place (e.g. heading_font, paragraph_font) stored as path to font file. When you update them, every theme variation that uses them will update live
- Stylebox variables: define stylebox (e.g. button_main_normal, button_main_hover), using color and number variables. 
- Texture variables: define a images in one place (e.g. cancel_icon). When you update them, every theme variation and stylebox that uses that color will be updated live.

- ThemeVariations can apply to different control types <br>
e.g. Panel and PanelContainer can have the same ThemeVariation, no need to define it twice. 
e.g. Label and Button can share a theme variation. shared properties like font_color will apply to both, otherwise properties are filtered based on which controls can use them.

- Quickly swap between themes so you can A/B different versions such as Dark/Light. 

### Installation
- Download the respository.
- Copy the files into res://addons/ThemeEditor/ folder
- Enable the addon in project settings<br>

### Getting Started
- Open the ThemeEditor in the bottom panel (next to output, debugger, audio etc.)
- Click the + button create a new theme. This will create a theme resrouce, and ".theme.json" file that stores all the variables and ThemeVariations with some reasonable defaults to get you started. 
- Click the <img src="icon_open.svg"> button to open a theme you've already created.
- Click the button with the theme name to activate that theme. Right click to close that theme (you cannot close the active theme)
- Click the <img src="icon_add.svg"> at the bottom to add a new theme variation. Double click the name to rename it.
- Click the name to see and edit the properties that apply to that theme variation
- Click the <img src="icon_edit.svg"> to change which Controls this theme variation can apply to

- Click the <img src="icon_settings.svg"> to open the variable editor. This will appear in the right dock where the inspector is by default.
- Change the variables and see the changes in real time.

### Applying to your scene
- Create a theme using the ThemeEditor
- Open your .tscn where you are making your UI
- Apply the .theme file that was created to your root node (or any node)
- When you select a control, you will see an option at the top of the inspector that allows you to quickly apply a valid theme variation to this control (based on the currently active theme in the ThemeInspector).
- Once you've applied all the theme variations, you can edit your variable and they will update in real time in your scene.
<br>
<img width="172" height="540" alt="image" src="https://github.com/user-attachments/assets/ff7a9605-6cfc-4253-98a9-de6cc1b1f4d5" />

### Troubleshooting
- if you're changing variables and they're not updating in your scene, make sure the active theme in the ThemeEditor is the same as the Theme applied to your scene.
