;+
; :Description:
;    Set up paths for KCor pipeline.
;
; :Author: sitongia
;-
pro kcor_paths

  common kcor_paths, bias_dir, flat_dir, mask_dir, binary_dir, $
    raw_basedir, process_basedir, hpss_gateway, $
    archive_dir, movie_dir, fullres_dir, log_dir
    
  case !VERSION.OS of
    'linux' : begin
      ; Calibration files
      bias_dir   = '/hao/kaula1/Data/KCor/bias/'
      flat_dir   = '/hao/kaula1/Data/KCor/flat/'
      mask_dir   = '/hao/kaula1/Data/KCor/mask/'
      
      ; Binary files
      binary_dir = '/hao/acos/sw/idl/KCor/Pipeline/'
      
      ; Processing
      raw_basedir     =      '/hao/mlsodata1/Data/KCor/raw/'
      process_basedir =      '/hao/kaula1/Data/KCor/process/'
      
      ; Distribution of results
      archive_dir = '/hao/acos/'
      movie_dir   = '/hao/acos/lowres/'
      fullres_dir = '/hao/acos/fullres/'
      
      ; HPSS Gateway directory
      hpss_gateway = '/hao/mlsodata3/Data/HPSS-Queue/KCor/'
      
      ; Log files
      log_dir = '/hao/acos/sw/var/log/KCor/'
    end
    
    'darwin' : begin
      if getenv('USER') eq 'dwijn' then begin
        ; Calibration files
        bias_dir   = '/Users/dwijn/academic/projects/csac/CoMP/bias/'
        flat_dir   = '/Users/dwijn/academic/projects/csac/CoMP/flat/'
        mask_dir   = '/hao/kaula1/Data/CoMP/mask/'
        
        ; Save files
        binary_dir = '/Users/dwijn/acadmemic/projects/csac/CoMP/Pipeline/'
        raw_synoptic_basedir     = '/hao/kaula1/Data/CoMP/raw_synoptic/'
        raw_usb_basedir     =      '/hao/kaula1/Data/CoMP/raw_rsync/'
        process_synoptic_basedir = '/hao/kaula1/Data/CoMP/process_synoptic/'
        process_usb_basedir =      '/hao/kaula1/Data/CoMP/process_usb/'
        
        ; Distribution of results
        archive_dir = '/Users/dwijn/academic/projects/csac/CoMP/archive/'
        movie_dir   = '/Users/dwijn/academic/projects/csac/CoMP/archive/lowres/'
        fullres_dir = '/Users/dwijn/academic/projects/csac/CoMP/archive/fullres/'
        
        ; Log files
        log_dir = '/Users/dwijn/academic/projects/csac/CoMP/'
      endif
            
      ; Processing
      ldm_basedir     = '/hoahu/e/mlso/comp/'
      usb_basedir     = '/Volumes/DATA/comp/'
    end
    
    'Win32' : begin
      if getenv('USERNAME') eq 'tomczyk' then begin
        ; Save files
        binary_dir = 'C:\Documents and Settings\tomczyk\My Documents\Pipeline\'
        defered_file = binary_dir + 'deferred.sav'
        ;hot_file =     binary_dir + 'hot_20110504.sav'
        hot_file =     binary_dir + 'hot_20120424.sav'
        
        raw_basedir     = 'E:\Comp\Raw\'
        process_basedir = 'E:\Comp\Reduced\'
        log_dir =         'E:\CoMP\log\'
      endif else begin
        ; Calibration files
        bias_dir   = 'X:\KCor\bias\'
        flat_dir   = 'X:\KCor\flat\'
        mask_dir   = 'X:\KCor\mask\'
        
        ; Binary files
        binary_dir = 'C:\Users\sitongia\Projects\KCor\Pipeline\'
        
        ; Processing
        ldm_basedir     =      ''
        ; On the HAO network
        raw_basedir     =      'L:\KCor\raw\'
        process_basedir =      'X:\KCor\process\'
        ; Local disk
;        raw_basedir     =      'D:\KCor\raw\'
;        process_basedir =      'D:\KCor\process\'
        
        ; Distribution of results
        archive_dir = 'C:\Users\sitongia\Data\KCor\archive\'
        movie_dir   = 'C:\Users\sitongia\Data\KCor\archive\lowres\'
        fullres_dir = 'C:\Users\sitongia\Data\KCor\archive\fullres\'
      
        ; HPSS Gateway directory
        hpss_gateway = '/hao/mlsodata3/Data/HPSS-Queue/KCor/'
        
        ; Log files
        log_dir = 'C:\Users\sitongia\Data\KCor\logs\'
      endelse
    end
    
  else : begin
    message, 'Unknown operating system'
  end
endcase

end