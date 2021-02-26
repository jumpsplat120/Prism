# Aila
 Artifical Intelligence Language Assistant. Lua/Love2d based voice assistant.
 
## Notes
The deepspeech module is complicated. My current setup has a lot of this stuff pre built, but it expects certain things:
	It expects you to have CUDA 10.1 and cuDNN v7.6.4.32 for CUDA 10.1 installed on your computer.
	It expects the system path variables for those to be on your computer (<install_location>/bin for both of them, and <install_location>/extras/CUPTI/lib64;<install_location>/include for CUDA).
	Obviously, since we're using CUDA, you have to have an Nvidia GPU. I have a GTX 1080. I don't know if it'll work OOB with other GPUs.
	You need to have the `libdeepspeech.so` file located next to either main.lua or the .exe if fused. (This is subject to change, I might try to setup some checks so this is done automatically.)
	A microphone. Deepspeech works with just raw audio files, but the version I distribute assumes you're doing real time speech to text, and so takes in audio from an input device.
	
If you can't do those things, or you like extra work, you can do all of this stuff manually. This is also for record keeping, so I remember how I managed to get this working in the first place. So, things to get deepspeech working for Windows 10:
	`cmake` from https://cmake.org/
	`native_client.amd64.gpu.win.tar.xz` from https://github.com/Mozilla/DeepSpeech/releases/tag/v0.9.3 (you also need the precompiled model)
	`luajit` from https://luajit.org/download/LuaJIT-2.1.0-beta3.zip
	`CUDA 10.1` from https://developer.nvidia.com/cuda-10.1-download-archive-update2?target_os=Windows&target_arch=x86_64 (Note that you have to have an Nvidia Dev login, free to make)
	`cuDNN v7.6.4.32 for CUDA 10.1` from https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.1_20191031/cudnn-10.1-windows10-x64-v7.6.5.32.zip (Also need that same Nvidia Dev login)
	`7zip` from https://www.7-zip.org/
	`lua-deepspeech` from https://github.com/bjornbytes/lua-deepspeech (just download the whole project)
	`Visual Studio Build Tools` from https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019 (This one, like any microsoft project, is a fucking ball ache. It might not work perfectly. If the tools themselves don't work, you may need to just download visual studio, and install the c/c++ version that comes with build tools.)

1. Download each thing listed above. Install the things that can be installed. Extract the things that can be extracted using 7zip.
2. Set up sys PATH. You need:
	a. Path to cmake.exe (This you might need to do in user PATH. idk, that's how it's setup in mine.)
	b. <install_location>/bin for cuDNN
	c. <install_location>/bin for CUDA
	d. <install_location>/extras/CUPTI/lib64 for CUDA
	e. <install_location>/include for CUDA
3. RESTART YOUR COMPUTER. The PATH vars aren't set until a restart.
4. Open up the build tools, and `cd` your way into the folder where you extracted the luajit stuff.
5. Drag drop the `msvcbuild.bat` onto the command prompt. It "should" run without any errors. If it has errors, fuck. Otherwise, you should get some files generated.
6. In the extracted folder for lua-deepspeech, open CMakeLists.text
7. Remove:
	a. `include(FindLua)`
	b. `find_package(Lua REQUIRED)`
8. Change:
	a. target_include_directories(lua-deepspeech PRIVATE "<location_of_src_folder>")
	b. target_link_libraries(lua-deepspeech PRIVATE "<location_of_src_folder>/lua51.lib")
9. Follow the build instruction on the lua-deepspeech page.
10. Point the `-deepspeech_path` to the extracted folder that came from the `native_client` tar
11. Go into the build folder, then Debug, and find lua-deepspeech.dll
12. Place the `libdeepspeech.so` file from the `native_client` tar into your project. If unfused, place it next to main.lua, otherwise place it next to the fused .exe.
13. Require the `lua-deepspeech.dll`
