const { Content } = require('./models');
const { syncDatabase } = require('./models');

async function checkLinkedInData() {
    await syncDatabase();
    const linkedinPosts = await Content.findAll({
        where: { status: 'published' }
    });
    
    console.log(`Total published posts: ${linkedinPosts.length}`);
    const filtered = linkedinPosts.filter(p => {
        const platformsObj = p.platforms || {};
        return Object.keys(platformsObj).some(k => k.toLowerCase() === 'linkedin');
    });
    console.log(`LinkedIn posts: ${filtered.length}`);
    filtered.forEach(p => {
        console.log(`- ID: ${p.id}, Title: ${p.title}, Platforms: ${JSON.stringify(p.platforms)}`);
    });
    process.exit(0);
}

checkLinkedInData().catch(err => {
    console.error(err);
    process.exit(1);
});
