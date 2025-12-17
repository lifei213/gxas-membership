
// Persona Logic & Visualization
class PersonaGenerator {
    static generateTags(profile) {
        const tags = new Set();
        
        // 1. Role/Level Tags
        if (profile.role === 'admin') tags.add('👑 系统管理员');
        if (profile.member_level) tags.add(`🏷️ ${profile.member_level}`);
        
        // 2. Position Tags
        if (profile.position) tags.add(`💼 ${profile.position}`);
        
        // 3. Mock Activity Tags (Since we don't have activity table yet)
        // In a real scenario, this would come from the DB
        const mockActivities = ['学术年会', '技术讲座', '行业交流'];
        const randomActivity = mockActivities[Math.floor(Math.random() * mockActivities.length)];
        tags.add(`🔥 ${randomActivity}积极分子`);
        
        // 4. Tenure Tag (Mock join date if missing)
        const joinDate = profile.created_at ? new Date(profile.created_at) : new Date('2023-01-01');
        const now = new Date();
        const years = now.getFullYear() - joinDate.getFullYear();
        if (years >= 1) tags.add('⭐ 资深会员');
        else tags.add('🌱 新锐会员');

        return Array.from(tags);
    }

    static generateIntro(profile, tags) {
        const name = profile.name || '会员';
        const position = profile.position || '从业者';
        const level = profile.member_level || '会员';
        
        const templates = [
            `我是 ${name}，一名 ${level}。作为 ${position}，我专注于自动化领域的创新与实践。`,
            `这里是 ${name} 的数字分身。我活跃于学会的各类活动中，致力于推动行业技术交流。`,
            `我是 ${name}，拥有 ${tags.length} 个专业标签。保持好奇，探索技术前沿是我的座右铭。`
        ];
        
        return templates[Math.floor(Math.random() * templates.length)];
    }

    static generateAbilityScores(profile) {
        // Mock scores based on profile data hash or random for demo
        // In production, these would be calculated from real activity data
        return [
            { name: '研究深度', value: 85, fill: '#8884d8' },
            { name: '实践能力', value: 78, fill: '#83a6ed' },
            { name: '学术交流', value: 90, fill: '#8dd1e1' },
            { name: '创新思维', value: 82, fill: '#82ca9d' },
            { name: '行业影响', value: 75, fill: '#a4de6c' }
        ];
    }
}

async function initPersona() {
    const profile = window.currentProfile;
    if (!profile) return;

    // Generate Data
    const tags = PersonaGenerator.generateTags(profile);
    const intro = PersonaGenerator.generateIntro(profile, tags);
    const scores = PersonaGenerator.generateAbilityScores(profile);

    // Render HTML
    const container = document.getElementById('persona-container');
    if (!container) return;

    container.innerHTML = `
        <div class="persona-card">
            <div class="persona-header">
                <div class="persona-avatar">
                    <span>${(profile.name || 'U')[0]}</span>
                </div>
                <div class="persona-title">
                    <h3>${profile.name || '会员'} 的数字分身</h3>
                    <p class="persona-id">ID: ${profile.id?.slice(0,8) || 'Unknown'}</p>
                </div>
            </div>
            
            <div class="persona-section">
                <h4><span class="icon">🤖</span> 学术画像</h4>
                <p class="persona-intro">${intro}</p>
            </div>

            <div class="persona-section">
                <h4><span class="icon">🏷️</span> 专业标签</h4>
                <div class="persona-tags">
                    ${tags.map(tag => `<span class="persona-tag">${tag}</span>`).join('')}
                </div>
            </div>

            <div class="persona-section">
                <h4><span class="icon">📊</span> 能力模型 (3D)</h4>
                <div id="persona-chart" style="width: 100%; height: 300px;"></div>
            </div>
        </div>
    `;

    // Render Chart using ECharts (replacing Recharts for vanilla JS compatibility)
    renderPersonaChart(scores);
}

function renderPersonaChart(data) {
    const chartDom = document.getElementById('persona-chart');
    if (!chartDom) return;
    
    const myChart = echarts.init(chartDom);
    
    const option = {
        tooltip: {
            trigger: 'item'
        },
        polar: {
            radius: [30, '80%']
        },
        angleAxis: {
            max: 100,
            startAngle: 75,
            axisLine: { show: false },
            axisTick: { show: false },
            axisLabel: { show: false },
            splitLine: { show: false }
        },
        radiusAxis: {
            type: 'category',
            data: data.map(d => d.name),
            axisLine: { show: false },
            axisTick: { show: false },
            axisLabel: { show: false } // Hide labels on axis, show in tooltip/legend or custom
        },
        series: [{
            type: 'bar',
            data: data.map(d => ({
                value: d.value,
                itemStyle: { color: d.fill }
            })),
            coordinateSystem: 'polar',
            label: {
                show: true,
                position: 'middle',
                formatter: '{b}: {c}'
            },
            roundCap: true,
            itemStyle: {
                shadowBlur: 10,
                shadowColor: 'rgba(0,0,0,0.1)'
            },
            animationEasing: 'cubicOut',
            animationDuration: 2000
        }]
    };

    myChart.setOption(option);
    
    // Resize handler
    window.addEventListener('resize', () => {
        myChart.resize();
    });
}
