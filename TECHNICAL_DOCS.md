# 广西自动化学会会员管理系统 - 深度技术说明书 (V2.0)

## 1. 总体架构设计

本系统采用现代化的 **BaaS (Backend as a Service)** 架构，结合 **Electron** 桌面容器技术，构建了一个安全、实时、跨平台的会员管理解决方案。

### 1.1 系统逻辑拓扑
```mermaid
graph TD
    User[用户终端 (Windows)] -->|UI渲染/交互| Electron[Electron 渲染进程]
    Electron -->|SQL/Auth| Supabase[Supabase 云端服务]
    Electron -->|AI推理| Volcengine[火山引擎 Ark API]
    Supabase -->|数据存储| Postgres[PostgreSQL 数据库]
    Supabase -->|文件存储| Storage[对象存储 Bucket]
    Volcengine -->|自然语言处理| LLM[Doubao-Pro 模型]
```

### 1.2 核心技术栈详细版本
*   **客户端容器**: Electron `28.0.0` (Chromium 120 + Node.js 18.18)
*   **前端框架**: Vanilla JS (ES2022) + HTML5 + CSS3 (无重型框架，保证轻量高效)
*   **数据库**: PostgreSQL 15.1 (Supabase 托管)
*   **ORM/SDK**: `@supabase/supabase-js` v2.39
*   **图表库**: Apache ECharts 5.5
*   **二维码引擎**: `qrcodejs`

---

## 2. 深度功能模块解析

### 2.1 认证与权限系统 (Auth & RLS)
这是系统的安全基石，实现了基于角色的访问控制 (RBAC)。

#### 2.1.1 认证流程 (`auth.js`)
1.  **登录**: 调用 `supabase.auth.signInWithPassword({ email, password })` 获取 JWT Token。
2.  **会话持久化**: Token 自动存储在 LocalStorage，Electron 重启后自动读取。
3.  **状态同步**: 页面加载时调用 `checkSession()`，若 Token 过期则强制重定向至 `index.html`。

#### 2.1.2 数据库权限 (Row Level Security)
我们没有在应用层做“软”权限控制，而是直接在数据库层实施了强制规则。即使攻击者绕过前端，也无法读取数据。

*   **Profiles 表策略**:
    *   *普通用户*: `auth.uid() = id` (只能看自己的)
    *   *管理员*: `is_admin() = true` (能看所有人的)
    *   *技术实现*:
        ```sql
        -- 安全定义函数 (Security Definer) 用于绕过 RLS 检查自身角色
        CREATE FUNCTION is_admin() RETURNS boolean AS $$
          SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
        $$ LANGUAGE sql SECURITY DEFINER;
        ```

### 2.2 动态数字分身系统 (AI Persona)
系统通过分析会员行为数据，自动生成“数字画像”。

#### 2.2.1 核心算法 (`personaGenerator.js`)
该模块是一个纯函数式工具类，无副作用。

*   **标签生成器 (`generateTags`)**:
    *   *输入*: 会员基础信息 + 活动记录数组
    *   *逻辑*:
        *   入会 > 10年 -> 🏷️ `元老会员`
        *   职业字段匹配 -> 🏷️ `专业:机器视觉`
        *   活动参与 > 5次 -> 🏷️ `活跃分子`
*   **雷达图计算 (`generateStats`)**:
    *   基于 5 个维度：学术力、活跃度、贡献值、影响力和资历。
    *   *算法*: `BaseScore (60) + RoleBonus (管理员+20) + LevelBonus (高级会员+15)`，并加入少量随机扰动模拟真实波动。

### 2.3 智能助手与文件分析
这是一个基于 RAG (检索增强生成) 思想的雏形实现。

#### 2.3.1 对话上下文构建
每次发送消息时，系统会动态构建 `System Prompt`，注入当前上下文：
```javascript
const systemPrompt = `
  你是一个简易会员管理系统的智能助手。
  当前用户：${name} (身份: ${role})
  系统规则：
  1. 管理员可导出Excel...
  2. 入会流程是...
`;
```
这确保了 AI 即使在没有微调的情况下，也能准确回答“我是谁”、“我有权做什么”等问题。

#### 2.3.2 文件上传与分析流程
1.  **上传**: 前端通过 `supabase.storage.upload()` 将文件传至 `chat-files` 桶。
2.  **鉴权**: 数据库触发器检查 `bucket_id = 'chat-files'` 且用户已登录。
3.  **生成链接**: 获取公开访问 URL (`getPublicUrl`)。
4.  **内容提取 (V2.1 新增)**:
    *   **PDF**: 使用 `pdf.js` 在客户端解析文本层。
    *   **Word (docx)**: 使用 `mammoth.js` 提取纯文本。
    *   **Text/Code**: 直接读取文本内容。
    *   **图片**: 使用 `tesseract.js` 进行客户端 OCR 识别（支持中英文）。
5.  **AI 投喂**: 将提取到的文本内容（截取前 20k 字符）直接注入 System Prompt，使 AI 能够“阅读”文件内容并回答相关问题。

---

## 3. 前端视觉与交互细节

### 3.1 3D 拟物化设计 (`style.css`)
为了实现“跃然纸上”的效果，我们精心调教了 CSS 属性。

*   **多重阴影 (Layered Shadows)**:
    不仅使用单一阴影，而是叠加环境光遮蔽和投射阴影。
    ```css
    --shadow-xl: 
      0 20px 25px -5px rgb(0 0 0 / 0.1),  /* 远距离模糊阴影 */
      0 8px 10px -6px rgb(0 0 0 / 0.1);   /* 近距离锐利阴影 */
    ```
*   **非线性动画 (Spring Physics)**:
    使用贝塞尔曲线模拟弹簧回弹，而非线性的 `ease-in-out`。
    ```css
    transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    /* 1.275 表示会超出目标值一点点再弹回来 */
    ```

### 3.2 动态主题引擎
*   **变量映射**: 所有颜色均定义为 CSS 变量 (`var(--primary-color)`)。
*   **运行时切换**:
    JS 监听切换事件 -> 读取配置对象 -> 遍历更新 `document.documentElement.style`。
    这比传统的 `class` 切换更灵活，支持从后端加载自定义颜色配置。

---

## 4. 数据库设计规范 (Schema)

### 4.1 核心表定义
*   **`profiles`**: 用户主表
    *   `id` (UUID, PK): 对应 Supabase Auth User ID。
    *   `ai_persona` (JSONB): 存储非结构化的画像数据，避免频繁改表结构。
*   **`forum_sections`**: 论坛板块（树形结构）
    *   `parent_id`: 支持多级子版块。
*   **`posts`**: 帖子
    *   `is_essence` (Boolean): 加精标志。
    *   `view_count`: 使用存储过程 `increment_view_count` 原子更新，防止并发写入丢失。

### 4.2 存储过程 (RPC)
为了性能和原子性，部分逻辑在数据库层执行：
*   `increment_view_count(post_id)`: 
    直接执行 `UPDATE posts SET view_count = view_count + 1`，比“查出来+1再写回去”快且安全。

---

## 5. 部署与运维

### 5.1 环境变量配置
在 `config.js` 中管理：
*   `SUPABASE_URL`: API 端点。
*   `SUPABASE_ANON_KEY`: 公开的 API Key（安全性依赖 RLS）。
*   `ARK_API_KEY`: AI 服务的密钥（注意：生产环境应通过后端转发，避免前端暴露）。

### 5.2 打包发布
使用 `electron-packager` 进行构建：
*   **命令**: `npx electron-packager . "App Name" --platform=win32 --arch=x64`
*   **资源处理**: `asar` 打包可选开启，用于隐藏源代码。
*   **输出**: 绿色免安装文件夹，包含 `ffmpeg.dll` 等 Chromium 依赖。

---

## 6. 已知限制与未来规划
*   **AI 限制**: 图片 OCR 功能依赖客户端计算能力，大图片识别可能较慢。
*   **即时通讯**: 聊天目前基于轮询或简单请求，未实现 WebSocket 全双工，消息延迟约 1-2 秒。
