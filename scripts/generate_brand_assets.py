import os
import re
import subprocess

def run(cmd):
    print("Running:", cmd)
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print("ERROR:", res.stderr)
        raise RuntimeError(f"Command failed: {cmd}\n{res.stderr}")
    return res.stdout

def clean_svg(svg_path):
    with open(svg_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Strip c2pa / manifest metadata
    content = re.sub(r'<metadata>[\s\S]*?</metadata>', '', content)
    content = re.sub(r'\s*xmlns:c2pa="[^"]*"', '', content)
    return content

def main():
    target_dir = "assets/brandings"
    os.makedirs(target_dir, exist_ok=True)

    mark_svg_path = f"{target_dir}/hyprwise_mark.svg"
    wordmark_svg_path = f"{target_dir}/hyprwise_wordmark.svg"

    # 1. Clean hyprwise_mark.svg and save as hyprwise_logo.svg
    cleaned_mark_svg = clean_svg(mark_svg_path)
    with open(f"{target_dir}/hyprwise_logo.svg", "w", encoding="utf-8") as f:
        f.write(cleaned_mark_svg)
    print("Created cleaned assets/brandings/hyprwise_logo.svg")

    # 2. Generate hyprwise_logo_white.svg for dark mode
    white_logo_svg = re.sub(r'stop-color="#[0-9a-fA-F]{3,6}"', 'stop-color="#FFFFFF"', cleaned_mark_svg)
    white_logo_svg = re.sub(r'fill="#[0-9a-fA-F]{3,6}"', 'fill="#FFFFFF"', white_logo_svg)
    with open(f"{target_dir}/hyprwise_logo_white.svg", "w", encoding="utf-8") as f:
        f.write(white_logo_svg)
    print("Created assets/brandings/hyprwise_logo_white.svg")

    # 3. Clean hyprwise_wordmark.svg
    cleaned_wordmark_svg = clean_svg(wordmark_svg_path)
    with open(f"{target_dir}/hyprwise_wordmark.svg", "w", encoding="utf-8") as f:
        f.write(cleaned_wordmark_svg)
    print("Created cleaned assets/brandings/hyprwise_wordmark.svg")

    # 4. Generate hyprwise_wordmark_white.svg
    white_wordmark_svg = re.sub(r'stop-color="#[0-9a-fA-F]{3,6}"', 'stop-color="#FFFFFF"', cleaned_wordmark_svg)
    white_wordmark_svg = re.sub(r'fill="#[0-9a-fA-F]{3,6}"', 'fill="#FFFFFF"', white_wordmark_svg)
    with open(f"{target_dir}/hyprwise_wordmark_white.svg", "w", encoding="utf-8") as f:
        f.write(white_wordmark_svg)
    print("Created assets/brandings/hyprwise_wordmark_white.svg")

    glow_png = f"{target_dir}/hyprwise_glow.png"
    wordmark_svg = f"{target_dir}/hyprwise_wordmark.svg"
    wordmark_white_svg = f"{target_dir}/hyprwise_wordmark_white.svg"

    # Remove obsolete old banner art if present
    old_banner_png = f"{target_dir}/hyprwise_banner_art.png"
    if os.path.exists(old_banner_png):
        os.remove(old_banner_png)
        print(f"Removed old banner {old_banner_png}")

    # 5. Android Adaptive Background (1024x1024 solid dark background)
    run(f"magick -size 1024x1024 xc:'#0F0F11' png24:{target_dir}/ic_launcher_background.png")

    # 6. Android Adaptive Foreground (1024x1024 transparent, mark scaled to 660x660 safe-zone)
    run(f"magick {glow_png} -resize 660x660 -background none -gravity center -extent 1024x1024 png32:{target_dir}/ic_launcher_foreground.png")

    # 7. Android Adaptive Monochrome (1024x1024 transparent white mask)
    run(f"magick {target_dir}/ic_launcher_foreground.png -alpha extract /tmp/alpha_mask.png")
    run("magick /tmp/alpha_mask.png -threshold 25% /tmp/white_mask.png")
    run(f"magick -size 1024x1024 xc:none -fill white /tmp/white_mask.png -alpha off -compose CopyOpacity -composite png32:{target_dir}/ic_launcher_monochrome.png")
    run("rm -f /tmp/alpha_mask.png /tmp/white_mask.png")

    # 8. Master App Icons (1024x1024, solid #0F0F11 background with centered glowing mark at 840x840)
    run(f"magick -size 1024x1024 xc:'#0F0F11' \\( {glow_png} -resize 840x840 \\) -gravity center -composite png24:{target_dir}/hyprwise_app_icon_1024.png")
    run(f"magick -size 1024x1024 xc:'#0F0F11' \\( {glow_png} -resize 840x840 \\) -gravity center -composite png24:{target_dir}/hyprwise_app_icon_ios_1024.png")

    # 9. Splash Screen Icons (512x512 transparent with centered glowing logo at 360x360)
    run(f"magick {glow_png} -resize 360x360 -background none -gravity center -extent 512x512 png32:{target_dir}/splash_icon_light.png")
    run(f"magick {glow_png} -resize 360x360 -background none -gravity center -extent 512x512 png32:{target_dir}/splash_icon_dark.png")

    # 10. Splash Screen Branding Banners (Generated directly from hyprwise_wordmark)
    run(f"magick -background none {wordmark_svg} -trim +repage -resize 640x png32:{target_dir}/branding_banner_light.png")
    run(f"magick -background none {wordmark_white_svg} -trim +repage -resize 640x png32:{target_dir}/branding_banner_dark.png")

    # 11. Web Favicon (192x192)
    run(f"magick -size 192x192 xc:'#0F0F11' \\( {glow_png} -resize 160x160 \\) -gravity center -composite png24:{target_dir}/favicon.png")

    print(f"All brand assets successfully generated in {target_dir}!")

if __name__ == "__main__":
    main()
