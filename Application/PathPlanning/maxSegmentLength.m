function m = maxSegmentLength(coords, depot)
%MAXSEGMENTLENGTH Maximum edge length on depot loop tour.

if isempty(coords)
    m = 0;
    return;
end

pts = coords;
if nargin > 1 && ~isempty(depot)
    pts = [depot; pts; depot];
end

if size(pts, 1) < 2
    m = 0;
    return;
end

diffs = diff(pts, 1, 1);
m = max(sqrt(sum(diffs .^ 2, 2)));

end
