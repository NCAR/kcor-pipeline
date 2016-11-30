function kcoruttestcase::init, _extra=e
  compile_opt strictarr

  if (~self->MGutTestCase::init(_extra=e)) then return, 0

  self.root = mg_src_root()

  return, 1
end


pro computtestcase__define
  compile_opt strictarr

  define = { KCorutTestCase, inherits MGutTestCase, $
             root: '' $
           }
end