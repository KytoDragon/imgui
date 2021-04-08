// dear imgui: standalone example application for Glfw + Vulkan
// If you are new to dear imgui, see examples/README.txt and documentation at the top of imgui.cpp.

// Important note to the reader who wish to integrate imgui_impl_vulkan.cpp/.h in their own engine/app.
// - Common ImGui_ImplVulkan_XXX functions and structures are used to interface with imgui_impl_vulkan.cpp/.h.
//   You will use those if you want to use this rendering back-end in your engine/app.
// - Helper ImGui_ImplVulkanH_XXX functions and structures are only used by this example (main.cpp) and by
//   the back-end itself (imgui_impl_vulkan.cpp), but should PROBABLY NOT be used by your own engine/app code.
// Read comments in imgui_impl_vulkan.h.

nothrow @nogc:

import ImGui = d_imgui.imgui;
import d_imgui.imgui_h;
import imgui_impl_glfw;
import imgui_impl_vulkan;
import core.stdc.stdio : printf, fprintf, stderr;   // #include <stdio.h>          // printf, fprintf
import core.stdc.stdlib : abort;                    // #include <stdlib.h>         // abort
//#define GLFW_INCLUDE_NONE
//#define GLFW_INCLUDE_VULKAN

import erupted;                                     // #include <vulkan/vulkan.h>
import bindbc.glfw;                                 // #include <GLFW/glfw3.h>
mixin(bindGLFW_Vulkan);                           // mixin vulkan related glfw functions

// [Win32] Our example includes a copy of glfw3.lib pre-compiled with VS2010 to maximize ease of testing and compatibility with old VS compilers.
// To link with VS2010-era libraries, VS2015+ requires linking with legacy_stdio_definitions.lib, which we do using this pragma.
// Your own project should not be affected, as you are likely to link with a newer binary of GLFW that is adequate for your version of Visual Studio.
//#if defined(_MSC_VER) && (_MSC_VER >= 1900) && !defined(IMGUI_DISABLE_WIN32_FUNCTIONS)
//#pragma comment(lib, "legacy_stdio_definitions")
//#endif


enum IMGUI_UNLIMITED_FRAME_RATE = true; //#define IMGUI_UNLIMITED_FRAME_RATE
debug enum IMGUI_VULKAN_DEBUG_REPORT = true;  // #ifdef _DEBUG

static VkAllocationCallbacks*   g_Allocator = null;
static VkInstance               g_Instance = VK_NULL_HANDLE;
static VkPhysicalDevice         g_PhysicalDevice = VK_NULL_HANDLE;
static VkDevice                 g_Device = VK_NULL_HANDLE;
static uint32_t                 g_QueueFamily = uint32_t.max;
static VkQueue                  g_Queue = VK_NULL_HANDLE;
static VkDebugReportCallbackEXT g_DebugReport = VK_NULL_HANDLE;
static VkPipelineCache          g_PipelineCache = VK_NULL_HANDLE;
static VkDescriptorPool         g_DescriptorPool = VK_NULL_HANDLE;

static ImGui_ImplVulkanH_Window g_MainWindowData;
static int                      g_MinImageCount = 2;
static bool                     g_SwapChainRebuild = false;

static void check_vk_result(VkResult err)
{
    if (err == 0)
        return;
    fprintf(stderr, "[vulkan] Error: VkResult = %d\n", err);
    if (err < 0)
        abort();
}

static if (IMGUI_VULKAN_DEBUG_REPORT)
{

    extern(System) VkBool32 debug_report(
        VkDebugReportFlagsEXT       flags,
        VkDebugReportObjectTypeEXT  objectType,
        uint64_t                    object,
        size_t                      location,
        int32_t                     messageCode,
        const(char)*              pLayerPrefix,
        const(char)*              pMessage,
        void*                       pUserData

       ) nothrow @nogc {

    //static VKAPI_ATTR VkBool32 VKAPI_CALL debug_report(VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64_t object, size_t location, int32_t messageCode, const(char)* pLayerPrefix, const(char)* pMessage, void* pUserData)
    //{
        //cast(void)flags; cast(void)object; cast(void)location; cast(void)messageCode; cast(void)pUserData; cast(void)pLayerPrefix; // Unused arguments
        fprintf(stderr, "[vulkan] Debug report from ObjectType: %i\nMessage: %s\n\n", objectType, pMessage);
        return VK_FALSE;
    }
}


static void SetupVulkan(const(char)*[] extensions)
{
    import core.stdc.stdlib : malloc, free;
    import erupted.vulkan_lib_loader;
    loadGlobalLevelFunctions;

    VkResult err;

    // Create Vulkan Instance
    {
        // Default information about the application, in case none was passed in by the user
        VkApplicationInfo app_info = {
            pEngineName         : "ErupteD_ImGui",
            engineVersion       : VK_MAKE_VERSION(0, 1, 0),
            pApplicationName    : "ErupteD_ImGui",
            applicationVersion  : VK_MAKE_VERSION(0, 1, 0),
            apiVersion          : VK_API_VERSION_1_0,
        };

        VkInstanceCreateInfo instance_ci;
        instance_ci.pApplicationInfo = & app_info;

        static if (IMGUI_VULKAN_DEBUG_REPORT)
        {
            // Enabling validation layers
            const(char)* layers = "VK_LAYER_KHRONOS_validation";
            instance_ci.enabledLayerCount = 1;
            instance_ci.ppEnabledLayerNames = & layers;

            // Enable debug report extension (we need additional storage, so we duplicate the user array to add our new extension to it)
            //const(char)** extensions_ext = cast(const(char)**)malloc((const(char)*).sizeof * (extension_count + 1));
            //memcpy(extensions_ext, extensions, extension_count * (const(char)*).sizeof);
            const(char)*[3]  extensions_ext;   // we know that glfw vulkan extensions have a count of 2 and that we just need one more
            extensions_ext[0 .. extensions.length] = extensions[];
            extensions_ext[extensions.length] = VK_EXT_DEBUG_REPORT_EXTENSION_NAME;
            instance_ci.enabledExtensionCount = extensions_ext.length;
            instance_ci.ppEnabledExtensionNames = extensions_ext.ptr;

            // Create Vulkan Instance
            vkCreateInstance(& instance_ci, g_Allocator, & g_Instance).check_vk_result;
            //free(extensions_ext);

            // load all instance based functions from the instance
            loadInstanceLevelFunctions(g_Instance);

            // Get the function pointer (required for any extensions)
            //auto vkCreateDebugReportCallbackEXT = cast(PFN_vkCreateDebugReportCallbackEXT)vkGetInstanceProcAddr(g_Instance, "vkCreateDebugReportCallbackEXT");
            //IM_ASSERT(vkCreateDebugReportCallbackEXT != null);

            // Setup the debug report callback
            VkDebugReportCallbackCreateInfoEXT debug_report_ci;
            debug_report_ci.flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT | VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT;
            debug_report_ci.pfnCallback = & debug_report;
            debug_report_ci.pUserData = null;
            vkCreateDebugReportCallbackEXT(g_Instance, & debug_report_ci, g_Allocator, & g_DebugReport).check_vk_result;

        }

        else
        {
            // Create Vulkan Instance without any debug feature
            instance_ci.enabledExtensionCount = extensions.length;
            instance_ci.ppEnabledExtensionNames = extensions;
            vkCreateInstance(& instance_ci, g_Allocator, & g_Instance).check_vk_result;

            // load all instance based functions from the instance
            loadInstanceLevelFunctions(g_Instance);

            IM_UNUSED(g_DebugReport);
        }
    }

    // Select GPU
    {
        uint32_t gpu_count;
        vkEnumeratePhysicalDevices(g_Instance, & gpu_count, null).check_vk_result;
        IM_ASSERT(gpu_count > 0);

        //VkPhysicalDevice* gpus = cast(VkPhysicalDevice*)malloc(VkPhysicalDevice.sizeof * gpu_count);
        VkPhysicalDevice[8] gpus;    // not expecting more then 8 (!) GPUs being installed
        vkEnumeratePhysicalDevices(g_Instance, & gpu_count, gpus.ptr).check_vk_result;

        // If a number >1 of GPUs got reported, you should find the best fit GPU for your purpose
        // e.g. VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU if available, or with the greatest memory available, etc.
        // for sake of simplicity we'll just take the first one, assuming it has a graphics queue family.
        g_PhysicalDevice = gpus[0];
    }

    // Select graphics queue family
    {
        uint32_t queue_family_property_count;
        vkGetPhysicalDeviceQueueFamilyProperties(g_PhysicalDevice, & queue_family_property_count, null);
        //VkQueueFamilyProperties* queues = cast(VkQueueFamilyProperties*)malloc(VkQueueFamilyProperties.sizeof * queue_family_property_count);
        VkQueueFamilyProperties[16] queue_family_properties;
        vkGetPhysicalDeviceQueueFamilyProperties(g_PhysicalDevice, & queue_family_property_count, queue_family_properties.ptr);
        for (uint32_t i = 0; i < queue_family_property_count; i++)
            if (queue_family_properties[i].queueFlags & VK_QUEUE_GRAPHICS_BIT)
            {
                g_QueueFamily = i;
                break;
            }
        //free(queue_family_properties);
        IM_ASSERT(g_QueueFamily != uint32_t.max);
    }

    // Create Logical Device (with 1 queue)
    {
        int device_extension_count = 1;
        const(char)* device_extensions = "VK_KHR_swapchain";
        const float queue_priority = 1.0f;
        VkDeviceQueueCreateInfo device_queue_ci;
        device_queue_ci.queueFamilyIndex = g_QueueFamily;
        device_queue_ci.queueCount = 1;
        device_queue_ci.pQueuePriorities = & queue_priority;
        VkDeviceCreateInfo device_ci;
        device_ci.queueCreateInfoCount = 1;
        device_ci.pQueueCreateInfos = & device_queue_ci;
        device_ci.enabledExtensionCount = device_extension_count;
        device_ci.ppEnabledExtensionNames = & device_extensions;
        vkCreateDevice(g_PhysicalDevice, & device_ci, g_Allocator, & g_Device).check_vk_result;

        // load all device based device level functions
        loadDeviceLevelFunctions(g_Device);

        // get the previously determined queue
        vkGetDeviceQueue(g_Device, g_QueueFamily, 0, & g_Queue);
    }

    // Create Descriptor Pool
    {
        uint32_t descriptor_type_count = 5;
        VkDescriptorPoolSize[11] descriptor_pool_sizes =
        [
            { VK_DESCRIPTOR_TYPE_SAMPLER, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, descriptor_type_count },
            { VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, descriptor_type_count }
       ];
        VkDescriptorPoolCreateInfo descriptor_pool_ci;
        descriptor_pool_ci.flags = VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT;
        descriptor_pool_ci.maxSets = descriptor_type_count * cast(uint32_t)descriptor_pool_sizes.length;
        descriptor_pool_ci.poolSizeCount = descriptor_pool_sizes.length;
        descriptor_pool_ci.pPoolSizes = descriptor_pool_sizes.ptr;
        vkCreateDescriptorPool(g_Device, & descriptor_pool_ci, g_Allocator, & g_DescriptorPool).check_vk_result;
    }
}

// All the ImGui_ImplVulkanH_XXX structures/functions are optional helpers used by the demo.
// Your real engine/app may not use them.
static void SetupVulkanWindow(ImGui_ImplVulkanH_Window* wd, VkSurfaceKHR surface, int width, int height)
{
    wd.Surface = surface;

    // Check for WSI support
    VkBool32 res;
    vkGetPhysicalDeviceSurfaceSupportKHR(g_PhysicalDevice, g_QueueFamily, wd.Surface, & res);
    if (res != VK_TRUE)
    {
        fprintf(stderr, "Error no WSI support on physical device 0\n");
        //exit(-1);
    }

    // Select Surface Format
    const VkFormat[4] requestSurfaceImageFormat = [VK_FORMAT_B8G8R8A8_UNORM, VK_FORMAT_R8G8B8A8_UNORM, VK_FORMAT_B8G8R8_UNORM, VK_FORMAT_R8G8B8_UNORM];
    const VkColorSpaceKHR requestSurfaceColorSpace = VK_COLORSPACE_SRGB_NONLINEAR_KHR;
    wd.SurfaceFormat = ImGui_ImplVulkanH_SelectSurfaceFormat(g_PhysicalDevice, wd.Surface, requestSurfaceImageFormat.ptr, requestSurfaceImageFormat.length, requestSurfaceColorSpace);

    // Select Present Mode
    static if (IMGUI_UNLIMITED_FRAME_RATE)
        VkPresentModeKHR[3] present_modes = [VK_PRESENT_MODE_MAILBOX_KHR, VK_PRESENT_MODE_IMMEDIATE_KHR, VK_PRESENT_MODE_FIFO_KHR];
    else
        VkPresentModeKHR[1] present_modes = [VK_PRESENT_MODE_FIFO_KHR];

    wd.PresentMode = ImGui_ImplVulkanH_SelectPresentMode(g_PhysicalDevice, wd.Surface, & present_modes[0], IM_ARRAYSIZE(present_modes));
    //printf("[vulkan] Selected PresentMode = %d\n", wd.PresentMode);

    // Create SwapChain, RenderPass, Framebuffer, etc.
    IM_ASSERT(g_MinImageCount >= 2);
    ImGui_ImplVulkanH_CreateOrResizeWindow(g_Instance, g_PhysicalDevice, g_Device, wd, g_QueueFamily, g_Allocator, width, height, g_MinImageCount);
}

static void CleanupVulkan()
{
    vkDestroyDescriptorPool(g_Device, g_DescriptorPool, g_Allocator);

    static if (IMGUI_VULKAN_DEBUG_REPORT)
    {
        // Remove the debug report callback
        auto vkDestroyDebugReportCallbackEXT = cast(PFN_vkDestroyDebugReportCallbackEXT)vkGetInstanceProcAddr(g_Instance, "vkDestroyDebugReportCallbackEXT");
        vkDestroyDebugReportCallbackEXT(g_Instance, g_DebugReport, g_Allocator);
    }

    vkDestroyDevice(g_Device, g_Allocator);
    vkDestroyInstance(g_Instance, g_Allocator);
}

static void CleanupVulkanWindow()
{
    ImGui_ImplVulkanH_DestroyWindow(g_Instance, g_Device, & g_MainWindowData, g_Allocator);
}

static void FrameRender(ImGui_ImplVulkanH_Window* wd, ImDrawData* draw_data)
{
    VkSemaphore image_acquired_semaphore  = wd.FrameSemaphores[wd.SemaphoreIndex].ImageAcquiredSemaphore;
    VkSemaphore render_complete_semaphore = wd.FrameSemaphores[wd.SemaphoreIndex].RenderCompleteSemaphore;

    VkResult acquire_result = vkAcquireNextImageKHR(g_Device, wd.Swapchain, uint64_t.max, image_acquired_semaphore, VK_NULL_HANDLE, & wd.FrameIndex);
    if (acquire_result == VK_ERROR_OUT_OF_DATE_KHR)
    {
        g_SwapChainRebuild = true;
        return;
    }
    acquire_result.check_vk_result;

    ImGui_ImplVulkanH_Frame* fd = & wd.Frames[wd.FrameIndex];
    {
        vkWaitForFences(g_Device, 1, & fd.Fence, VK_TRUE, uint64_t.max).check_vk_result;    // wait indefinitely instead of periodically checking
        vkResetFences(g_Device, 1, & fd.Fence).check_vk_result;
    }
    {
        vkResetCommandPool(g_Device, fd.CommandPool, 0).check_vk_result;
        VkCommandBufferBeginInfo cmd_buffer_bi;
        cmd_buffer_bi.flags |= VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        vkBeginCommandBuffer(fd.CommandBuffer, & cmd_buffer_bi).check_vk_result;
    }
    {
        VkRenderPassBeginInfo render_pass_bi;
        render_pass_bi.renderPass = wd.RenderPass;
        render_pass_bi.framebuffer = fd.Framebuffer;
        render_pass_bi.renderArea.extent.width = wd.Width;
        render_pass_bi.renderArea.extent.height = wd.Height;
        render_pass_bi.clearValueCount = 1;
        render_pass_bi.pClearValues = & wd.ClearValue;
        vkCmdBeginRenderPass(fd.CommandBuffer, & render_pass_bi, VK_SUBPASS_CONTENTS_INLINE);
    }

    // Record dear imgui primitives into command buffer
    ImGui_ImplVulkan_RenderDrawData(draw_data, fd.CommandBuffer);

    // Submit command buffer
    vkCmdEndRenderPass(fd.CommandBuffer);
    {
        VkPipelineStageFlags wait_stage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        VkSubmitInfo submit_info;
        submit_info.waitSemaphoreCount = 1;
        submit_info.pWaitSemaphores = & image_acquired_semaphore;
        submit_info.pWaitDstStageMask = & wait_stage;
        submit_info.commandBufferCount = 1;
        submit_info.pCommandBuffers = & fd.CommandBuffer;
        submit_info.signalSemaphoreCount = 1;
        submit_info.pSignalSemaphores = & render_complete_semaphore;

        vkEndCommandBuffer(fd.CommandBuffer).check_vk_result;
        vkQueueSubmit(g_Queue, 1, & submit_info, fd.Fence).check_vk_result;
    }
}

static void FramePresent(ImGui_ImplVulkanH_Window* wd)
{
    if (g_SwapChainRebuild)
        return;
    VkSemaphore render_complete_semaphore = wd.FrameSemaphores[wd.SemaphoreIndex].RenderCompleteSemaphore;
    VkPresentInfoKHR present_info;
    present_info.waitSemaphoreCount = 1;
    present_info.pWaitSemaphores = & render_complete_semaphore;
    present_info.swapchainCount = 1;
    present_info.pSwapchains = & wd.Swapchain;
    present_info.pImageIndices = & wd.FrameIndex;

    VkResult present_result = vkQueuePresentKHR(g_Queue, & present_info);
    if (present_result == VK_ERROR_OUT_OF_DATE_KHR)
    {
        g_SwapChainRebuild = true;
        return;
    }
    present_result.check_vk_result;
    wd.SemaphoreIndex = (wd.SemaphoreIndex + 1) % wd.ImageCount; // Now we can use the next set of semaphores
}

extern(C) void glfw_error_callback(int error, const(char)* description) nothrow
{
    fprintf(stderr, "Glfw Error %d: %s\n", error, description);
}

int main()
{
    // Setup GLFW window

    // Initialize GLFW3 and Vulkan related glfw functions
    loadGLFW("glfw3");  // load the lib found in system path
    loadGLFW_Vulkan;    // load vulkan specific glfw function pointers
    glfwSetErrorCallback(& glfw_error_callback);

    if (!glfwInit())
        return 1;

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow* window = glfwCreateWindow(1280, 720, "Dear ImGui GLFW+Vulkan example", null, null);

    // Setup Vulkan
    if (!glfwVulkanSupported())
    {
        printf("GLFW: Vulkan Not Supported\n");
        return 1;
    }
    uint32_t extension_count = 0;
    const(char)** extensions = glfwGetRequiredInstanceExtensions(& extension_count);
    SetupVulkan(extensions[0 .. extension_count]);

    // Create Window Surface
    VkSurfaceKHR surface;
    glfwCreateWindowSurface(g_Instance, window, g_Allocator, & surface).check_vk_result;

    // Create Framebuffers
    int w, h;
    glfwGetFramebufferSize(window, & w, & h);
    ImGui_ImplVulkanH_Window* wd = & g_MainWindowData;
    SetupVulkanWindow(wd, surface, w, h);

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui.CreateContext();
    ImGuiIO* io = & ImGui.GetIO();  // (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    //ImGui.StyleColorsDark();
    //ImGui.StyleColorsClassic();

    // Setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForVulkan(window, true);
    ImGui_ImplVulkan_InitInfo init_info;
    init_info.Instance = g_Instance;
    init_info.PhysicalDevice = g_PhysicalDevice;
    init_info.Device = g_Device;
    init_info.QueueFamily = g_QueueFamily;
    init_info.Queue = g_Queue;
    init_info.PipelineCache = g_PipelineCache;
    init_info.DescriptorPool = g_DescriptorPool;
    init_info.Allocator = g_Allocator;
    init_info.MinImageCount = g_MinImageCount;
    init_info.ImageCount = wd.ImageCount;
    init_info.CheckVkResultFn = & check_vk_result;
    ImGui_ImplVulkan_Init(& init_info, wd.RenderPass);

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui.PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return null. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.md' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts.AddFontDefault();
    //io.Fonts.AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts.AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //io.Fonts.AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts.AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    //ImFont* font = io.Fonts.AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, null, io.Fonts.GetGlyphRangesJapanese());
    //IM_ASSERT(font != null);

    // Upload Fonts
    {
        // Use any command queue
        VkCommandPool command_pool = wd.Frames[wd.FrameIndex].CommandPool;
        VkCommandBuffer command_buffer = wd.Frames[wd.FrameIndex].CommandBuffer;

        vkResetCommandPool(g_Device, command_pool, 0).check_vk_result;
        VkCommandBufferBeginInfo begin_info;
        begin_info.flags |= VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        vkBeginCommandBuffer(command_buffer, & begin_info).check_vk_result;

        ImGui_ImplVulkan_CreateFontsTexture(command_buffer);

        VkSubmitInfo end_info;
        end_info.commandBufferCount = 1;
        end_info.pCommandBuffers = & command_buffer;
        vkEndCommandBuffer(command_buffer).check_vk_result;
        vkQueueSubmit(g_Queue, 1, & end_info, VK_NULL_HANDLE).check_vk_result;

        vkDeviceWaitIdle(g_Device).check_vk_result;
        ImGui_ImplVulkan_DestroyFontUploadObjects();
    }

    // Our state
    bool show_demo_window = true;
    bool show_another_window = false;
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    // Main loop
    while (!glfwWindowShouldClose(window))
    {
        // Poll and handle events (inputs, window resize, etc.)
        // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
        // - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
        // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
        // Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
        glfwPollEvents();

        // Resize swap chain?
        if (g_SwapChainRebuild)
        {
            int width, height;
            glfwGetFramebufferSize(window, & width, & height);
            if (width > 0 && height > 0)
            {
                ImGui_ImplVulkan_SetMinImageCount(g_MinImageCount);
                ImGui_ImplVulkanH_CreateOrResizeWindow(g_Instance, g_PhysicalDevice, g_Device, & g_MainWindowData, g_QueueFamily, g_Allocator, width, height, g_MinImageCount);
                g_MainWindowData.FrameIndex = 0;
                g_SwapChainRebuild = false;
            }
        }

        // Start the Dear ImGui frame
        ImGui_ImplVulkan_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui.NewFrame();

        // 1. Show the big demo window (Most of the sample code is in ImGui.ShowDemoWindow()! You can browse its code to learn more about Dear ImGui!).
        import d_imgui.imgui_demo : ShowDemoWindow;
        if (show_demo_window)
            ShowDemoWindow(& show_demo_window);

        import d_imgui.imgui_widgets;
        // 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
        {
            static float f = 0.0f;
            static int counter = 0;

            ImGui.Begin("Hello, world!");                          // Create a window called "Hello, world!" and append into it.

            Text("This is some useful text.");               // Display some text (you can use a format strings too)
            Checkbox("Demo Window", & show_demo_window);      // Edit bools storing our window open/close state
            Checkbox("Another Window", & show_another_window);

            SliderFloat("float", & f, 0.0f, 1.0f);            // Edit 1 float using a slider from 0.0f to 1.0f
            ColorEdit3("clear color", clear_color.array); // Edit 3 floats representing a color

            if (Button("Button"))                            // Buttons return true when clicked (most widgets return true when edited/activated)
                counter++;
            //ImGui.SameLine();
            //Text("counter = %d", counter);
            //Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui.GetIO().Framerate, ImGui.GetIO().Framerate);
            ImGui.End();
        }

        // 3. Show another simple window.
        if (show_another_window)
        {
            ImGui.Begin("Another Window", & show_another_window);   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
            Text("Hello from another window!");
            if (Button("Close Me"))
                show_another_window = false;
            ImGui.End();
        }

        // Rendering
        ImGui.Render();
        ImDrawData* draw_data = ImGui.GetDrawData();
        const bool is_minimized = (draw_data.DisplaySize.x <= 0.0f || draw_data.DisplaySize.y <= 0.0f);
        if (!is_minimized)
        {
            memcpy(& wd.ClearValue.color.float32[0], & clear_color, 4 * float.sizeof);
            FrameRender(wd, draw_data);
            FramePresent(wd);
        }
    }

    // Cleanup
    vkDeviceWaitIdle(g_Device).check_vk_result;
    ImGui_ImplVulkan_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui.DestroyContext();

    CleanupVulkanWindow();
    CleanupVulkan();

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
