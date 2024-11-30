import sys
from PIL import Image, ImageOps

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: {0} <image to convert>".format(sys.argv[0]))

    else:
        input_fname = sys.argv[1]
        image_in = Image.open(input_fname).convert("L")
        image_in = image_in.convert('RGB')


        w, h = image_in.size

        # Take input image and divide each color channel's value by 16
        #preview = image_in.copy()
        image_out = image_in.copy()
        image_out.save('preview.png')


        # # Palettize the image
        # print('Output image preview saved at preview.png')
        # palette = image_out.getpalette()
        # rgb_tuples = [tuple(palette[i:i+3]) for i in range(0, 3*num_colors_out, 3)]

        # # Save pallete
        # with open(f'palette.mem', 'w') as f:
        #     f.write( '\n'.join( [f'{r:02x}{g:02x}{b:02x}' for r, g, b in rgb_tuples] ) )

        # print('Output image pallete saved at palette.mem')

        # Save the image itself
        with open(f'image.mem', 'w') as f:
            for y in range(h):
                for x in range(w):
                    # f.write(f'{image_out.getpixel((x,y))}\n')
                    r,g,b = image_out.getpixel((x,y))
                    f.write(f'{r:02x}{g:02x}{b:02x}\n')

        print('Output image saved at image.mem')


