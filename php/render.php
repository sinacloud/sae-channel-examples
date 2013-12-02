<?php
function render_template($template_file, $variables) 
{
    extract($variables, EXTR_SKIP);  // Extract the variables to a local namespace
    ob_start();                      // Start output buffering
    include "./$template_file";      // Include the template file
    $contents = ob_get_contents();   // Get the contents of the buffer
    ob_end_clean();                  // End buffering and discard
    return $contents;                // Return the contents
}
