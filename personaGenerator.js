// utils/personaGenerator.js

class PersonaGenerator {
    // Based on member behavior generate tags
    static generateTags(memberData, activities) {
        const tags = new Set();

        // 1. Professional Field Tags
        if (memberData.professional_field) {
            const fields = memberData.professional_field.split(',');
            fields.forEach(field => tags.add(`专业:${field.trim()}`));
        } else if (memberData.position) {
            // Fallback to position if professional_field is missing
            tags.add(`职务:${memberData.position}`);
        }

        // 2. Activity Participation Tags
        if (activities && activities.length > 0) {
            // Group activities by type
            const counts = {};
            activities.forEach(a => {
                const type = a.activity_type || 'unknown';
                counts[type] = (counts[type] || 0) + 1;
                tags.add(`活动:${type}`);
            });

            // Check for "Active Member"
            const totalActivities = activities.length;
            if (totalActivities > 5) {
                tags.add('活跃分子');
            }
        } else {
            // Mock tags if no activities found (for demo purposes)
            if (Math.random() > 0.5) tags.add('潜力新人');
        }

        // 3. Membership Seniority Tags
        const joinDate = memberData.join_date ? new Date(memberData.join_date) : new Date(memberData.created_at || Date.now());
        const joinYears = new Date().getFullYear() - joinDate.getFullYear();
        
        if (joinYears >= 10) tags.add('元老会员');
        else if (joinYears >= 5) tags.add('资深会员');
        else if (joinYears < 1) tags.add('新晋会员');

        // Extra: Role based
        if (memberData.role === 'admin') tags.add('系统管理员');
        if (memberData.is_student) tags.add('学生会员');

        return Array.from(tags);
    }

    // Generate AI Intro
    static generateAIIntro(memberData, tags) {
        const name = memberData.name || '会员';
        const org = memberData.organization || memberData.unit || '所在单位';
        
        // Helper to get top tags
        const topTags = this.getTopTags(tags, 3);
        const topTagsStr = topTags.length > 0 ? topTags.join('、') : '多项技能';

        const templates = [
            `我是${name}，一位专注于${topTagsStr}的自动化领域专业人士。`,
            `${name}，${this.getSeniority(tags)}自动化专家，在${org}从事相关工作。`,
            `作为${this.getActivityLevel(tags)}，我活跃于学会的各类活动中。`
        ];

        return templates[Math.floor(Math.random() * templates.length)];
    }

    // Helper: Get top N tags (filter out some structural tags if needed)
    static getTopTags(tags, n) {
        // Filter out "Activity:" prefix for better readability in sentence
        const cleanTags = tags.map(t => t.replace(/^(专业:|活动:|职务:)/, ''));
        return cleanTags.slice(0, n);
    }

    // Helper: Get seniority description
    static getSeniority(tags) {
        if (tags.includes('元老会员')) return '资深元老级';
        if (tags.includes('资深会员')) return '经验丰富的';
        if (tags.includes('新晋会员')) return '充满活力的';
        return '专业的';
    }

    // Helper: Get activity level description
    static getActivityLevel(tags) {
        if (tags.includes('活跃分子')) return '学会的活跃中坚';
        return '学会的一员';
    }

    // Generate Stats for Chart
    static generateStats(memberData, activityMetrics = {}) {
        let base = 60;
        if (memberData.role === 'admin') base += 20;
        if (memberData.member_level === 'senior' || memberData.member_level === '高级会员') base += 15;
        if (memberData.is_student) base -= 5;

        const random = () => Math.floor(Math.random() * 15);
        
        // Calculate dynamic scores based on forum activity
        const postCount = activityMetrics.postCount || 0;
        const commentCount = activityMetrics.commentCount || 0;
        
        // Academic Exchange: Heavily influenced by posts and comments
        // Base 60 + 5 points per post + 2 points per comment, max 95
        let academicScore = 60 + (postCount * 5) + (commentCount * 2);
        academicScore = Math.min(95, academicScore);
        
        // Industry Influence: Influenced by posts (content creation)
        let influenceScore = base + (postCount * 3);
        influenceScore = Math.min(95, influenceScore);

        return [
            { name: '研究深度', value: Math.min(100, base + random()), color: '#8884d8' },
            { name: '实践能力', value: Math.min(100, base + random() + (memberData.is_student ? 10 : 0)), color: '#83a6ed' },
            { name: '学术交流', value: academicScore, color: '#8dd1e1' }, // Dynamic
            { name: '创新思维', value: Math.min(100, base + random()), color: '#82ca9d' },
            { name: '行业影响', value: influenceScore, color: '#a4de6c' } // Dynamic
        ];
    }

    // Generate Analysis Record
    static generateAnalysis(memberData, stats, activityMetrics = {}) {
        const postCount = activityMetrics.postCount || 0;
        const commentCount = activityMetrics.commentCount || 0;
        const totalInteractions = postCount + commentCount;
        
        let analysis = "";
        
        // 1. Opening based on activity
        if (totalInteractions === 0) {
            analysis += "您在学术论坛中暂时处于潜水状态。";
        } else if (totalInteractions < 5) {
            analysis += "您在学术论坛中初露头角，开始参与讨论。";
        } else {
            analysis += "您是学术论坛的活跃贡献者，积极分享观点。";
        }

        // 2. Specific Stat Highlight
        const academicStat = stats.find(s => s.name === '学术交流');
        if (academicStat && academicStat.value > 80) {
            analysis += "您的【学术交流】指数表现优异，显示出强烈的分享意愿。";
        }

        // 3. Suggestion / Encouragement
        if (postCount === 0) {
            analysis += "建议您尝试发布第一篇学术帖子，展示您的研究成果，这将显著提升您的【行业影响】指数。";
        } else if (commentCount === 0) {
            analysis += "多参与他人帖子的讨论，可以进一步提升您的【学术交流】评分。";
        } else {
            analysis += "请继续保持活跃，您的贡献正在帮助构建更繁荣的学术社区。";
        }

        return analysis;
    }
}

// Expose to window for global access
window.PersonaGenerator = PersonaGenerator;
