# .latexmkrc - Configuration for latexmk

# Basic settings
$pdf_mode = 1;
$postscript_mode = 0;
$dvi_mode = 0;
$bibtex_use = 2;  # Run bibtex automatically

# Get environment variables
$final = $ENV{'FINAL'};
$interactive = $ENV{'INTERACTIVE'};
$verbose = $ENV{'VERBOSE'};

# Set TEXINPUTS to include all subdirectories for robust path resolution
# This allows \includegraphics{file} to work from any subdirectory
$ENV{'TEXINPUTS'} = join(':', 
    '.',
    './assignment:',
    './exam:',
    './quiz:',
    './note:',
    './slide:',
    './lab-manual:',
    './figure:',
    './question:',
    './formula:',
    $ENV{'TEXINPUTS'} || ''
);

# Set BIBINPUTS so bibtex can find master.bib in the root directory
# and any bibliography files in subdirectories
$ENV{'BIBINPUTS'} = join(':', 
    '.',
    './note:',
    './assignment:',
    './exam:',
    './quiz:',
    './slide:',
    './lab-manual:',
    $ENV{'BIBINPUTS'} || ''
);

# Cleanup settings
$clean_ext = 'bbl synctex.gz';
$clean_full_ext = 'fdb_latexmk fls';

