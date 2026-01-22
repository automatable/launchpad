/**
 * Minimal favicon generator following 2025 best practices
 *
 * Generates only the essential files:
 * - favicon.ico (32x32 for legacy browsers)
 * - apple-touch-icon.png (180x180 with solid background for iOS)
 * - icon-192.png (for Android/PWA)
 * - icon-512.png (for PWA splash screens)
 *
 * The source favicon.svg is used directly by modern browsers.
 * Reference: https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs
 */
import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SOURCE_FILE = path.join(__dirname, '../static/favicon.svg');
const OUTPUT_DIR = path.join(__dirname, '../static');
const BACKGROUND_COLOR = { r: 34, g: 34, b: 34 }; // #222222

// Verify source file exists
if (!fs.existsSync(SOURCE_FILE)) {
  console.error('ERROR: favicon.svg not found in static/ directory!');
  console.error('Please ensure favicon.svg exists before running this script.');
  process.exit(1);
}

/**
 * Icon configurations - only the essentials
 */
const ICONS = [
  // Apple Touch Icon - needs solid background (iOS doesn't support transparency)
  { name: 'apple-touch-icon.png', size: 180, withBackground: true },
  // PWA icons - transparent background
  { name: 'icon-192.png', size: 192, withBackground: false },
  { name: 'icon-512.png', size: 512, withBackground: false },
];

/**
 * Generate a PNG icon with optional solid background
 */
async function generateIcon(baseImage, config) {
  const { name, size, withBackground } = config;
  const outputPath = path.join(OUTPUT_DIR, name);

  if (withBackground) {
    // Create solid background and composite the logo on top (80% of icon size)
    const logoSize = Math.floor(size * 0.8);
    const padding = Math.floor((size - logoSize) / 2);

    const logoBuffer = await baseImage
      .clone()
      .resize(logoSize, logoSize, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      })
      .png()
      .toBuffer();

    await sharp({
      create: {
        width: size,
        height: size,
        channels: 3,
        background: BACKGROUND_COLOR
      }
    })
      .composite([{ input: logoBuffer, top: padding, left: padding }])
      .png()
      .toFile(outputPath);
  } else {
    // Transparent background
    await baseImage
      .clone()
      .resize(size, size, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      })
      .png({ alpha: true })
      .toFile(outputPath);
  }

  console.log(`✓ Generated ${name} (${size}×${size})`);
}

/**
 * Generate favicon.ico
 * Note: Sharp outputs PNG format. For a proper ICO, you'd need a dedicated library.
 * However, modern browsers handle PNG-in-ICO just fine. For true multi-resolution ICO,
 * consider using 'png-to-ico' package or similar.
 */
async function generateICO(baseImage) {
  const outputPath = path.join(OUTPUT_DIR, 'favicon.ico');

  // Generate 32x32 PNG - browsers handle this as ICO fallback
  await baseImage
    .clone()
    .resize(32, 32, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 }
    })
    .png({ alpha: true })
    .toFile(outputPath);

  console.log('✓ Generated favicon.ico (32×32)');
}

/**
 * Main execution
 */
async function main() {
  console.log('Generating minimal favicon set (2025 best practices)...\n');

  try {
    const baseImage = sharp(SOURCE_FILE).ensureAlpha();

    // Generate all PNG icons
    for (const config of ICONS) {
      await generateIcon(baseImage, config);
    }

    // Generate ICO for legacy browsers
    await generateICO(baseImage);

    console.log('\n✓ All favicons generated successfully!');
    console.log('\nFiles generated:');
    console.log('  - favicon.svg (source, used by modern browsers)');
    console.log('  - favicon.ico (legacy browsers)');
    console.log('  - apple-touch-icon.png (iOS home screen)');
    console.log('  - icon-192.png (Android/PWA)');
    console.log('  - icon-512.png (PWA splash)');
  } catch (error) {
    console.error('Error generating favicons:', error);
    process.exit(1);
  }
}

main();
