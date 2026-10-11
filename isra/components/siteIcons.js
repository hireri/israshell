.pragma library

const browsers = /^(zen|helium|firefox|librewolf|chromium|google-chrome|brave|vivaldi|microsoft-edge)/i;
const suffix = /\s[—–-]\s(zen browser|mozilla firefox|librewolf|chromium|google chrome|brave|vivaldi|microsoft edge)$/i;

const sites = [
    [/\byoutube\b/i, "youtube"],
    [/\bgithub\b/i, "github"],
    [/\bgitlab\b/i, "gitlab"],
    [/\bdiscord\b/i, "discord"],
    [/\bspotify\b/i, "spotify"],
    [/\btwitch\b/i, "twitch"],
    [/\breddit\b/i, "reddit"],
    [/\bnetflix\b/i, "netflix"],
    [/\bwikipedia\b/i, "wikipedia"],
    [/\bclaude\b/i, "claude"],
    [/\bfigma\b/i, "figma"],
    [/\bnotion\b/i, "notion"],
    [/\btelegram\b/i, "telegram"],
    [/\bwhatsapp\b/i, "whatsapp"],
    [/\bgmail\b/i, "gmail"],
    [/\btwitter\b|^x$/i, "x"],
];

function match(appId, title) {
    if (!title || !browsers.test(appId))
        return null;
    const parts = title.replace(suffix, "").split(/\s[-–—|·\/]\s/);
    for (const seg of [parts[parts.length - 1], parts[0]]) {
        for (const [re, icon] of sites) {
            if (re.test(seg.trim()))
                return icon;
        }
    }
    return null;
}
