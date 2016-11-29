function parabola,x,y

;  function to return minimum position of parabola given 3 data points

return,x[2]-(y[2]-y[1])/(y[2]-2.*y[1]+y[0]) -0.5
end
