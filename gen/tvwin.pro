pro tvwin, dat, index=index

;procedure to open window and display image

if ~keyword_set(index) then index=0

s=size(dat)

window, index, xs=s(1),ys=s(2),xpos=300

tvscl,dat

end