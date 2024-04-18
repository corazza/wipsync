from PIL import Image, ImageDraw, ImageFont

# Create an image with white background
img = Image.new("RGB", (1920, 1080), color=(255, 255, 255))

# Initialize the drawing context with the image object as background
draw = ImageDraw.Draw(img)

# Set the font (using a built-in default font)
font = ImageFont.load_default()

# Position of the text
text = "Did you commit and push your code today?"
# Get text size
textwidth, textheight = draw.textsize(text, font=font)
x = (img.width - textwidth) / 2
y = (img.height - textheight) / 2

# Apply text to image
draw.text((x, y), text, font=font, fill=(0, 0, 0))

# Save the image
img.save("reminder.png")

print("Image saved as 'reminder.png'")
