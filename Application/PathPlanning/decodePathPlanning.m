function order = decodePathPlanning(x, nTasks)
%DECODEPATHPLANNING Random-key decoding -> visit order 1..nTasks.

x = x(:)';
if numel(x) < nTasks
    x = [x, rand(1, nTasks - numel(x))];
end
[~, order] = sort(x(1:nTasks), 'ascend');

end
