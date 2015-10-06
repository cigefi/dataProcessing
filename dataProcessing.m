function [out] = dataProcessing(dirName,var2Read,yearZero,yearN)
    if nargin < 1
        error('dataProcessing: dirName is a required input')
    end
    if nargin < 2
        error('dataProcessing: var2Read is a required input')
    end
    if nargin < 3 % Validates if the yearZero param is received
        yearZero = 0; % Default value
    end
    if nargin < 4 % Validates if the yearN param is received
        yearN = 0; % Default value
    end
    
    if(yearZero > yearN) % Validates if the yearZero is higher to the yearN
        yearTemp = yearZero;
        yearZero = yearN;
        yearN = yearTemp;
    end
    dirData = dir(dirName);  % Get the data for the current directory
    path = java.lang.String(dirName);
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    
    for f = 3:length(dirData)
        fileT = path.concat(dirData(f).name);
        if(fileT.substring(fileT.lastIndexOf('.')+1).equalsIgnoreCase('nc'))
            yearC = str2num(fileT.substring(fileT.length-7,fileT.lastIndexOf('.')));
            if(yearZero>0)
                if(yearC<yearZero) 
                    continue;
                 end
            end
            if(yearN>0)
                if(yearC>yearN)
                    continue;
                end
            end
            nc_varget(fileT,var2Read);
            disp(yearC);
            disp(fileT); % Netcdf files
        end
    end
end
