; docformat = 'rst'

pro kcor_make_docs
  compile_opt strictarr

  idldoc, root='src', output='api-docs', /use_latex, /embed
end
