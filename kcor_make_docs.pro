; docformat = 'rst'

pro kcor_make_docs
  compile_opt strictarr

  args = command_line_args(count=nargs)
  root = nargs gt 1L ? args[0] : mg_src_root()   ; location of this file

  idldoc, root=filepath('src', root=root), $
          output='api-docs', $
          title='KCor pipeline', $
          subtitle=' IDL API documentation', $
          /statistics, $
          /use_latex, $
          /embed
end
