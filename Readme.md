### NAME

    App-GUI-Harmonograph - Cyperharmonograph draws beautiful circular images

### VERSION
 
    0.50

[Home on CPAN](https://metacpan.org/pod/App-Harmonograph)

    This is the landing page for the user documentation.
    There is also a download link on the left side under "Tools".
   

### BUILDING

    The git repository contains much more than the software package itself.
    If you check out sources here, you have to build the package yourself.
    In order to do that you need perl and the module Dist::Zilla.
    
    cpan install Dist::Zilla   
        or 
    cpanm Dist::Zilla

    
    Then you have to check which further the Dist::Zilla plugins you miss:
    
    dzil authordeps
    
    and pipe them into your preferred installer:
    
    dzil authordeps | cpanm
    
  
    Than you can build a release yourself:

    dzil build
    
    Which gives you basically the same tgz file as under the download link
    from CPAN (as describes under HOME), just with more up to date 
    (and maybe buggy) sources. Don't forget to:
    
    dzil clean


### INSTALLING

    Once you downloaded or created a build, you unzip it and do the usual:
 
        perl Makefile.PL
        make
        make test
        make install

    This should install to your site_perl directory.


### PREREQUISITES

    Perl 5.12 including some core Modules.
    FindBin
    File::Spec
    File::HomeDir
    Graphics::Toolkit::Color
    WxPerl 0.9 or higher
   


[CHANGES](https://github.com/lichtkind/App-GUI-Harmonograph/blob/main/Changes) (with roadmap)

[CONTRIBUTING](https://github.com/lichtkind/App-GUI-Harmonograph/blob/main/CONTRIBUTING)

### COPYRIGHT

    Copyright(c) 2022 Herbert Breunung,

    All rights reserved.  This program is free software; you can
    redistribute it and/or modify it under GPL version 3
