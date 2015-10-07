% Function dataProcessing
%
% Prototype: dataProcessing(dirName,var2Read,yearZero,yearN)
%            dataProcessing(dirName,var2Read)
%
% dirName = Path of the directory that contents the files 
% var2Read = Variable to be read (use 'ncdump' to check variable names)
% yearZero (Optional) = Lower year of the data to be read
% yearN (Optional) = Higher year of the data to be read
function [out,meanOut] = dataProcessing(dirName,var2Read,yearZero,yearN)
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
    
    out = 0;
    for f = 3:length(dirData)
        fileT = path.concat(dirData(f).name);
        if(fileT.substring(fileT.lastIndexOf('.')+1).equalsIgnoreCase('nc'))
            try
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
                if(yearC > 0)
                    if(out==0)
                        out = nc_varget(char(fileT),var2Read);
                    else
                        nData = nc_varget(char(fileT),var2Read);
                        out = cat(1,out,nData);
                    end
                end
            catch
                continue;
            end
        end
    end
    
    for m=1:1:length(out(:,1,1))
        for n=1:1:length(out(1,:,1))
            for k=1:1:length(out(1,1,:))
                %meanOut(m,n,k)= mean(out(:,n,k));
                meanOut(1,n,k) = mean(out(:,n,k)); %#ok<AGROW>
            end
        end
    end
end
