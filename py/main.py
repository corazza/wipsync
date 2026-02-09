from PIL import Image, ImageDraw, ImageFont

# Create an image with white background
img = Image.new("RGB", (1920, 1080), color=(255, 255, 255))

# Initialize the drawing context with the image object as background
draw = ImageDraw.Draw(img)

# Set the font (using the built-in default font at a readable size)
# Pillow >= 10.1 supports load_default(size=...) for a scalable font
try:
    font = ImageFont.load_default(size=48)
except TypeError:
    # Fallback for older Pillow versions that don't accept size=
    font = ImageFont.load_default()

# Position of the text
text = "Did you commit and push your code today?"

# Get text bounding box (textsize was removed in Pillow 10.0)
bbox = draw.textbbox((0, 0), text, font=font)
textwidth = bbox[2] - bbox[0]
textheight = bbox[3] - bbox[1]
x = (img.width - textwidth) / 2
y = (img.height - textheight) / 2

# Apply text to image
draw.text((x, y), text, font=font, fill=(0, 0, 0))

# Save the image
img.save("reminder.png")

print("Image saved as 'reminder.png'")
