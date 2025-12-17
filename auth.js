// Initialize Supabase Client
// Assumes supabase-js is loaded via CDN and config.js is loaded before this file
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Login Function
async function login(email, password) {
    // Clear previous session data just in case
    // await supabaseClient.auth.signOut(); 

    const { data, error } = await supabaseClient.auth.signInWithPassword({
        email,
        password
    });
    
    if (error) throw error;
    
    // Login successful, redirect to dashboard
    window.location.href = "dashboard.html";
}

// Helper to get base URL for redirects (handles subdirectories like GitHub Pages)
function getBaseUrl() {
    const path = window.location.pathname;
    const pathSegments = path.split('/');
    // Remove the last segment if it is a file name (contains dot)
    if (pathSegments[pathSegments.length - 1].includes('.')) {
        pathSegments.pop();
    }
    const basePath = pathSegments.join('/');
    return window.location.origin + basePath;
}

// Register Function
async function register(email, password) {
    const baseUrl = getBaseUrl();
    const { data, error } = await supabaseClient.auth.signUp({
        email,
        password,
        options: {
            // Redirect to this page after email verification
            emailRedirectTo: `${baseUrl}/index.html` 
        }
    });
    
    if (error) throw error;
    
    if (data.user && !data.session) {
        showMessage("注册成功！确认邮件已发送至您的邮箱，请点击邮件中的链接完成验证。", "success");
    } else if (data.user && data.session) {
        showMessage("注册成功！正在自动登录...", "success");
        setTimeout(() => {
            window.location.href = "dashboard.html";
        }, 1500);
    } else {
        // Should not happen usually
        showMessage("注册请求已发送，请检查您的邮箱。", "info");
    }
}

// Send Password Reset Email
async function sendPasswordResetEmail(email) {
    const baseUrl = getBaseUrl();
    const { data, error } = await supabaseClient.auth.resetPasswordForEmail(email, {
        redirectTo: `${baseUrl}/dashboard.html?reset=true`,
    });
    
    if (error) throw error;
    return data;
}

// Update User Password (for logged in users)
async function updateUserPassword(newPassword) {
    const { data, error } = await supabaseClient.auth.updateUser({
        password: newPassword
    });
    
    if (error) throw error;
    return data;
}

// Logout Function
async function logout() {
    const { error } = await supabaseClient.auth.signOut();
    if (error) {
        alert("退出失败: " + error.message);
    } else {
        window.location.href = "index.html";
    }
}

// Get User Role
async function getUserRole() {
    try {
        const { data: { user } } = await supabaseClient.auth.getUser();
        
        if (!user) return null;

        const { data, error } = await supabaseClient
            .from('profiles')
            .select('*') // 使用 select('*') 以避免因缺少字段导致的错误
            .eq('id', user.id)
            .maybeSingle();

        if (error) throw error;
        
        return data;
    } catch (error) {
        console.error("获取角色失败:", error);
        return null;
    }
}

// Check Session (for dashboard protection)
async function checkSession() {
    try {
        const { data: { session } } = await supabaseClient.auth.getSession();
        if (!session) {
            window.location.href = "index.html";
        }
        return session;
    } catch (e) {
        alert("网络错误，无法连接到服务器: " + e.message);
        throw e;
    }
}
