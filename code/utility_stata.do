clear all
set more off

* check again
program main

	* packages with ado (for checking whether installed).
	local ssc_packages grstyle listtab resize missings sxpose
	
    if !missing("`ssc_packages'") {
        foreach pkg of local ssc_packages {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'.ado
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }
	
	* other packages
	* palettes
	capture which palettes.hlp
	if _rc == 111 {                 
	   dis "Installing palettes"
	   quietly ssc install palettes, replace
	   }	

	* labutil
	capture which labcd.ado
	if _rc == 111 {                 
	   dis "Installing labutil"
	   quietly ssc install labutil, replace
	   }		 
	   

     * Install packages using net, but avoid re-installing if already present
     capture which grc1leg
        if _rc != 0 { // need to install
         quietly net from "http://www.stata.com/users/vwiggins/"
         quietly cap ado uninstall grc1leg
         quietly net install grc1leg
		 dis "Installing grc1leg"
        }
     * Install packages using net, but avoid re-installing if already present
     capture which renvars
        if _rc != 0 { // need to install
         quietly net from "http://www.stata.com/stb/stb60"
         quietly cap ado uninstall dm88
         quietly net install dm88
		 dis "Installing dm88"
        }
		
end

main
