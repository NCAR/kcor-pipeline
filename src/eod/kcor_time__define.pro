; docformat = 'rst'

function kcor_time::type, letter
  compile_opt strictarr

  case strlowcase(letter) of
    'c': return, 'cal'
    'm': return, 'dev'
    't': return, 'sat'
    'b': return, 'bri'
    'd': return, 'dim'
    'o': return, 'cloudy'
    'n': return, 'noisy'
    'e': return, 'eng'
    'g': return, 'good'
    else: return, 'unk'
  endcase
end



function kcor_time::getVariable, name, found=found
  compile_opt strictarr

  found = 1B

  raw_basedir = self.run->config('processing/raw_basedir')

  case strlowcase(name) of
    'datetime': return, self.datetime
    'type': begin
        quicklook_href = self->getVariable('quicklook_href', found=found)
        if (~found) then return, 'unk'
        letter = strmid(file_basename(quicklook_href, '.gif'), 0, 1, /reverse_offset)
        return, self->type(letter)
      end
    'quicklook_href': begin
        quicklooks = file_search(filepath(self.datetime + '*', $
                                          subdir=[self.run.date, 'level0', 'quicklook'], $
                                          root=raw_basedir), $
                                 count=n_quicklooks)
        if (n_quicklooks eq 0L) then return, ''
        quicklook_href = './level0/quicklook/' + file_basename(quicklooks[0])
        return, quicklook_href
      end
    'l15_href': begin
        l15_gifs = file_search(filepath(self.datetime + '_kcor_l1.5.gif', $
                                        subdir=[self.run.date, 'level1'], $
                                        root=raw_basedir), $
                               count=n_l15_gifs)
        if (n_l15_gifs eq 0L) then return, ''
        l15_href = './level1/' + file_basename(l15_gifs[0])
        return, l15_href
      end
    'l15_cropped_href': begin
        l15_cropped_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_cropped.gif', $
                                                subdir=[self.run.date, 'level1'], $
                                                root=raw_basedir), $
                                       count=n_l15_cropped_gifs)
        if (n_l15_cropped_gifs eq 0L) then return, ''
        l15_cropped_href = './level1/' + file_basename(l15_cropped_gifs[0])
        return, l15_cropped_href
      end
    'nrgf_href': begin
        nrgf_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_nrgf.gif', $
                                        subdir=[self.run.date, 'level1'], $
                                        root=raw_basedir), $
                               count=n_nrgf_gifs)
        if (n_nrgf_gifs eq 0L) then return, ''
        nrgf_href = './level1/' + file_basename(nrgf_gifs[0])
        return, nrgf_href
      end
    'nrgf_cropped_href': begin
        nrgf_cropped_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_nrgf_cropped.gif', $
                                                 subdir=[self.run.date, 'level1'], $
                                                 root=raw_basedir), $
                                        count=n_nrgf_cropped_gifs)
        if (n_nrgf_cropped_gifs eq 0L) then return, ''
        nrgf_cropped_href = './level1/' + file_basename(nrgf_cropped_gifs[0])
        return, nrgf_cropped_href
      end
    'avg_href': begin
        avg_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_avg.gif', $
                                        subdir=[self.run.date, 'level1'], $
                                        root=raw_basedir), $
                               count=n_avg_gifs)
        if (n_avg_gifs eq 0L) then return, ''
        avg_href = './level1/' + file_basename(avg_gifs[0])
        return, avg_href
      end
    'avg_cropped_href': begin
        avg_cropped_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_avg_cropped.gif', $
                                                 subdir=[self.run.date, 'level1'], $
                                                 root=raw_basedir), $
                                        count=n_avg_cropped_gifs)
        if (n_avg_cropped_gifs eq 0L) then return, ''
        avg_cropped_href = './level1/' + file_basename(avg_cropped_gifs[0])
        return, avg_cropped_href
      end
    'diff_href': begin
        diff_gifs = file_search(filepath(self.datetime + '_kcor_minus_*.gif', $
                                        subdir=[self.run.date, 'level1'], $
                                        root=raw_basedir), $
                               count=n_diff_gifs)
        if (n_diff_gifs eq 0L) then return, ''
        diff_href = './level1/' + file_basename(diff_gifs[0])
        return, diff_href
      end
    'diff_quality': begin
        diff_gifs = file_search(filepath(self.datetime + '_kcor_minus_*.gif', $
                                        subdir=[self.run.date, 'level1'], $
                                        root=raw_basedir), $
                               count=n_diff_gifs)
        if (n_diff_gifs eq 0L) then return, ''
        basename = file_basename(diff_gifs[0], '.gif')
        diff_quality = strmid(basename, strpos(basename, '_', /reverse_search) + 1)
        return, diff_quality
      end
    'nomask_href': begin
        nomask_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_nomask.gif', $
                                           subdir=[self.run.date, 'level1'], $
                                           root=raw_basedir), $
                                  count=n_nomask_gifs)
        if (n_nomask_gifs eq 0L) then return, ''
        nomask_href = './level1/' + file_basename(nomask_gifs[0])
        return, nomask_href
      end
    'nomask_cropped_href': begin
        nomask_cropped_gifs = file_search(filepath(self.datetime + '_kcor_l1.5_cropped_nomask.gif', $
                                                   subdir=[self.run.date, 'level1'], $
                                                   root=raw_basedir), $
                                        count=n_nomask_cropped_gifs)
        if (n_nomask_cropped_gifs eq 0L) then return, ''
        nomask_cropped_href = './level1/' + file_basename(nomask_cropped_gifs[0])
        return, nomask_cropped_href
      end
  endcase

  found = 0B
  return, ''
end


function kcor_time::init, datetime, run=run
  compile_opt strictarr

  self.datetime = datetime
  self.run = run

  return, 1
end


pro kcor_time__define
  compile_opt strictarr

  !null = {kcor_time, inherits IDL_Object, $
           datetime: '', $
           run: obj_new()}
end
