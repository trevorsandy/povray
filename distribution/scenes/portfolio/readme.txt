
The goal of the portfolio is to show most of
the standard patterns, objects and items in
the standard include files.

The portfolio is generated by rendering all
the .INI files (except __empty.ini) in this
directory. This will render all the images 
specified in the POV files and write the
HTML files for the images to be shown in.
These files are accessible through index.html.
The total amount of data will be ~ 16.5 MB.

When rendering the INI files, make sure
there is nothing left on the command-line to
interfere with the process. The images will
be written as PNG files.

The layout of the Portfolio is kept simple,
but can easily be changed.

- The size of the images is set in the INI
  file. Changing it will automatically
  change the size in the image-tag for the
  HTML files.

- The amount of images per page is set in
  the POV file, the macro parameters:
  'NumPicHorizontal' and 'NumPicVertical'.

- Other changes, like the background color
  have to be made directly in the 'HTMLgen'
  macro in 'html_gen.inc'.

- For adding your own stuff to the Portfolio
  the template files '__empty_.pov' and 
  '__empty.ini' are included.

