function len = tourLength(coords, depot)
%TOURLENGTH Closed tour length through coordinates (optional depot start/end).

if isempty(coords)
    len = 0;
    return;
end

if size(coords, 1) == 1
    if nargin > 1 && ~isempty(depot)
        len = 2 * norm(coords - depot);
    else
        len = 0;
    end
    return;
end

pts = coords;
if nargin > 1 && ~isempty(depot)
    pts = [depot; pts; depot];
end

diffs = diff(pts, 1, 1);
len = sum(sqrt(sum(diffs .^ 2, 2)));

end
