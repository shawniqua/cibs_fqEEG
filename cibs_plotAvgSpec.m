function cibs_plotAvgSpec(cspec, isdel)

chavgDB = @(spec) 10*log10(mean([spec.S],2));
delcol = 'brk';

plot(cspec(1).f, chavgDB(cspec), 'Color', delcol(isdel+1)); hold on
findobj(gca)
lhs = findobj(gca);
gcln = lhs(2);
curcol = gcln.Color;
cspec(1)
a = [cspec.Serr];
a = reshape(a,[2 length(cspec(1).f) 4]);
avgserr = mean(a,3);
plot(cspec(1).f,10*log10(avgserr), 'Color', curcol)
end