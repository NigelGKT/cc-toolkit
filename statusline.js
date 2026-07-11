#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');

let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(input); } catch { console.log(''); return; }

  const model = data.model?.display_name || data.model?.id || '?';
  const dir = path.basename(data.workspace?.current_dir || data.cwd || '');

  const pctRaw = data.context_window?.used_percentage;
  const pct = pctRaw == null ? null : Math.floor(pctRaw);

  const CYAN = '\x1b[36m', GREEN = '\x1b[32m', YELLOW = '\x1b[33m', RED = '\x1b[31m', RESET = '\x1b[0m';
  const ctxColor = pct == null ? RESET : pct >= 90 ? RED : pct >= 70 ? YELLOW : GREEN;
  const ctxLabel = pct == null ? 'ctx: --' : `ctx: ${pct}%`;

  let branch = '';
  try {
    const cwd = data.workspace?.current_dir || data.cwd || process.cwd();
    branch = execSync('git branch --show-current', { cwd, encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }).trim();
  } catch {}

  // Line 1: folder | branch
  const line1 = [`📁 ${dir}`];
  if (branch) line1.push(`🌿 ${branch}`);
  console.log(line1.join(' | '));

  // Line 2: model | effort | context% | cost | duration | lines changed
  const fmtElapsed = ms => {
    const totalMin = Math.floor((ms || 0) / 60000);
    const h = Math.floor(totalMin / 60), m = totalMin % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };
  const line2 = [`${CYAN}[${model}]${RESET}`];
  if (data.effort?.level) line2.push(`eff: ${data.effort.level}`);
  line2.push(`${ctxColor}${ctxLabel}${RESET}`);
  if (data.cost) {
    const cost = data.cost.total_cost_usd ?? 0;
    const added = data.cost.total_lines_added ?? 0;
    const removed = data.cost.total_lines_removed ?? 0;
    line2.push(`💰 $${cost.toFixed(2)}`);
    line2.push(`⏱ ${fmtElapsed(data.cost.total_duration_ms)}`);
    if (added > 0 || removed > 0) line2.push(`+${added}/-${removed}`);
  }
  console.log(line2.join(' | '));

  // Second line: session (5h) + weekly rate-limit usage bars. Absent until the
  // first API response of a session, and only present for Claude.ai subscribers.
  const barColor = p => p >= 90 ? RED : p >= 70 ? YELLOW : GREEN;
  const bar = (p, width = 10) => {
    const filled = Math.round((p / 100) * width);
    return '▓'.repeat(filled) + '░'.repeat(width - filled);
  };
  const fmtDuration = sec => {
    if (sec == null || sec <= 0) return '0h 00m';
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
    return `${h}h ${String(m).padStart(2, '0')}m`;
  };
  const fmtDateTime = epochSec => {
    const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const d = new Date(epochSec * 1000);
    const hh = String(d.getHours()).padStart(2, '0');
    const mm = String(d.getMinutes()).padStart(2, '0');
    return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${hh}:${mm}`;
  };

  const rl = data.rate_limits;
  if (rl?.five_hour?.used_percentage != null) {
    const p = Math.round(rl.five_hour.used_percentage);
    const left = rl.five_hour.resets_at != null
      ? fmtDuration(rl.five_hour.resets_at - Math.floor(Date.now() / 1000))
      : '--';
    console.log(`[session] ${barColor(p)}${bar(p)}${RESET} ${p}% | resets in ${left}`);
  }
  if (rl?.seven_day?.used_percentage != null) {
    const p = Math.round(rl.seven_day.used_percentage);
    const when = rl.seven_day.resets_at != null ? fmtDateTime(rl.seven_day.resets_at) : '--';
    console.log(`[week] ${barColor(p)}${bar(p)}${RESET} ${p}% | resets ${when}`);
  }
});
