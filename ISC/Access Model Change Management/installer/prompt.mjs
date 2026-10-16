import readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';

/**
 * Read a line with each character echoed as `*` only.
 * Requires exclusive access to stdin (no active readline interface).
 */
function readSecret(promptText) {
  return new Promise((resolve, reject) => {
    if (!input.isTTY) {
      // Non-interactive (piped): read a normal line without echo control.
      let buf = '';
      output.write(promptText);
      const onData = (chunk) => {
        buf += chunk;
        if (buf.includes('\n') || buf.includes('\r')) {
          input.off('data', onData);
          resolve(buf.replace(/[\r\n]+$/, ''));
        }
      };
      input.on('data', onData);
      return;
    }

    const chars = [];
    output.write(promptText);

    const wasRaw = input.isRaw;
    input.setRawMode(true);
    input.resume();
    input.setEncoding('utf8');

    const cleanup = () => {
      input.off('data', onData);
      try {
        input.setRawMode(wasRaw);
      } catch {
        // ignore — terminal may already be restored
      }
    };

    const onData = (chunk) => {
      const text = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
      for (const ch of text) {
        const code = ch.charCodeAt(0);
        // Enter / Return
        if (ch === '\r' || ch === '\n') {
          cleanup();
          output.write('\n');
          resolve(chars.join(''));
          return;
        }
        // Ctrl+C
        if (code === 3) {
          cleanup();
          output.write('\n');
          reject(new Error('Interrupted'));
          return;
        }
        // Ctrl+D with empty input
        if (code === 4) {
          cleanup();
          output.write('\n');
          resolve(chars.join(''));
          return;
        }
        // Backspace / Delete
        if (ch === '\u007f' || ch === '\b') {
          if (chars.length) {
            chars.pop();
            output.write('\b \b');
          }
          continue;
        }
        // Ignore other control characters
        if (code < 32) continue;

        chars.push(ch);
        output.write('*');
      }
    };

    input.on('data', onData);
  });
}

function openReadline() {
  return readline.createInterface({ input, output, terminal: !!input.isTTY });
}

export async function createPrompter() {
  let rl = openReadline();

  const ask = async (question, { defaultValue, secret = false } = {}) => {
    const hint = defaultValue !== undefined ? ` [${defaultValue}]` : '';
    const label = `${question}${hint}: `;

    let answer;
    if (secret) {
      // Drop readline so it cannot echo plaintext alongside our `*` mask.
      rl.close();
      try {
        answer = (await readSecret(label)).trim();
      } finally {
        rl = openReadline();
      }
    } else {
      answer = (await rl.question(label)).trim();
    }

    if (!answer && defaultValue !== undefined) return defaultValue;
    return answer;
  };

  const choose = async (question, options) => {
    output.write(`\n${question}\n`);
    options.forEach((opt, i) => {
      output.write(`  [${i + 1}] ${opt.label}\n`);
    });
    for (;;) {
      const raw = await ask('Choose a number');
      const idx = Number(raw) - 1;
      if (idx >= 0 && idx < options.length) return options[idx];
      output.write('Invalid choice.\n');
    }
  };

  const multiChoose = async (question, options, { defaultAll = false } = {}) => {
    output.write(`\n${question}\n`);
    output.write('  [0] None\n');
    options.forEach((opt, i) => {
      output.write(`  [${i + 1}] ${opt.label}\n`);
    });
    const emptyHint = defaultAll
      ? 'leave empty for all'
      : 'leave empty for none';
    output.write(`  Enter comma-separated numbers (0 = none; ${emptyHint})\n`);
    const raw = await ask('Selection');
    if (!raw) return defaultAll ? [...options] : [];
    const nums = raw.split(',').map((s) => Number(s.trim()));
    if (nums.includes(0)) return [];
    return nums
      .map((n) => n - 1)
      .filter((i) => i >= 0 && i < options.length)
      .map((i) => options[i]);
  };

  const close = () => {
    try {
      rl.close();
    } catch {
      // already closed
    }
  };

  return { ask, choose, multiChoose, close };
}
