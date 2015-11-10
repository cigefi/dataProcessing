% Function dataProcessing
%
% Prototype: dataProcessing(dirName,var2Read,yearZero,yearN)
%            dataProcessing(dirName,var2Read)
%            dataProcessing(dirName)
%
% dirName = Path of the directory that contents the files 
% var2Read (Recommended)= Variable to be read (use 'ncdump' to check variable names)
% yearZero (Optional) = Lower year of the data to be read
% yearN (Optional) = Higher year of the data to be read
function [] = dataProcessing(dirName,var2Read,yearZero,yearN)
    if nargin < 1
        error('dataProcessing: dirName is a required input')
    end
    if nargin < 2 % Validates if the var2Read param is received
        temp = java.lang.String(dirName).split('/');n
        temp = temp(end).split('_');
        var2Read = char(temp(1)); % Default value is taken from the path
    end
    if nargin < 3 % Validates if the yearZero param is received
        yearZero = 0; % Default value
    end
    if nargin < 4 % Validates if the yearN param is received
        yearN = 0; % Default value
    end
    
    if(yearZero > yearN) % Validates if the yearZero is higher than yearN
        yearTemp = yearZero;
        yearZero = yearN;
        yearN = yearTemp;
    end
    dirData = dir(dirName);  % Get the data for the current directory
    months = [31,28,31,30,31,30,31,31,30,31,30,31]; % Reference to the number of days per month
    monthsName = {'January','February','March','April','May','June','July','August','September','October','November','December'};
    path = java.lang.String(dirName);
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
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
                    % Subrutine to writte the data in new Netcdf file
                    writeFile(fileT,var2Read,yearC,months,path,monthsName);
                end
            catch
                continue;
            end
        else
            if isequal(dirData(f).isdir,1)
                  newPath = char(path.concat(dirData(f).name));
                if nargin < 2 % Validates if the var2Read param is received
                    dataProcessing(newPath);
                elseif nargin < 3 % Validates if the yearZero param is received
                    dataProcessing(newPath,var2Read);
                elseif nargin < 4 % Validates if the yearN param is received
                    dataProcessing(newPath,var2Read,yearZero)
                else
                    dataProcessing(newPath,var2Read,yearZero,yearN)
                end
            end
        end
    end
end

function [] = writeFile(fileT,var2Read,yearC,months,path,monthsName)
    % Catching data from original file
    latDataSet = nc_varget(char(fileT),'lat'); 
    lonDataSet = nc_varget(char(fileT),'lon');
    timeDataSet = nc_varget(char(fileT),var2Read);
    lPos = 0;
    newName = strcat('[CIGEFI] ',num2str(yearC),'.nc');
    h = waitbar(0,'Initializing data writing ...');
    for m=1:1:length(months)
        fPos = lPos + 1;
        if(leapyear(yearC)&& m ==2 && length(timeDataSet(:,1,1))==366)
            lPos = months(m) + fPos; % Leap year
        else
            lPos = months(m) + fPos - 1;
        end
        if(m==1) % New file configuration
            newFile = char(path.concat(newName));
            nc_create_empty(newFile,'netcdf4-classic');

            % Adding file dimensions
            nc_add_dimension(newFile,'latitude',length(latDataSet));
            nc_add_dimension(newFile,'longitude',length(lonDataSet));
            nc_add_dimension(newFile,'time',0); % 0 means UNLIMITED dimension

            % Global params
            nc_attput(newFile,nc_global,'parent_experiment',nc_attget(char(fileT),nc_global,'parent_experiment'));
            nc_attput(newFile,nc_global,'parent_experiment_id',nc_attget(char(fileT),nc_global,'parent_experiment_id'));
            nc_attput(newFile,nc_global,'parent_experiment_rip',nc_attget(char(fileT),nc_global,'parent_experiment_rip'));
            nc_attput(newFile,nc_global,'institution',nc_attget(char(fileT),nc_global,'institution'));
            nc_attput(newFile,nc_global,'realm',nc_attget(char(fileT),nc_global,'realm'));
            nc_attput(newFile,nc_global,'modeling_realm',nc_attget(char(fileT),nc_global,'modeling_realm'));
            nc_attput(newFile,nc_global,'version',nc_attget(char(fileT),nc_global,'version'));
            nc_attput(newFile,nc_global,'downscalingModel',nc_attget(char(fileT),nc_global,'downscalingModel'));
            nc_attput(newFile,nc_global,'experiment_id',nc_attget(char(fileT),nc_global,'experiment_id'));
            nc_attput(newFile,nc_global,'frequency','monthly');
            nc_attput(newFile,nc_global,'Year',num2str(yearC)); % nc_attput(FILE,VARIABLE,TITLE,CONTENT)
            nc_attput(newFile,nc_global,'reinterpreted_institution','CIGEFI - Universidad de Costa Rica');
            nc_attput(newFile,nc_global,'reinterpreted_date',char(datetime('today')));
            nc_attput(newFile,nc_global,'reinterpreted_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

            % Adding file variables
            monthlyData.Name = var2Read;
            monthlyData.Datatype = 'single';
            monthlyData.Dimension = {'time','latitude', 'longitude'};
            nc_addvar(newFile,monthlyData);

            timeData.Name = 'time';
            timeData.Dimension = {'time'};
            nc_addvar(newFile,timeData);

            latData.Name = 'latitude';
            latData.Dimension = {'latitude'};
            nc_addvar(newFile,latData);

            lonData.Name = 'longitude';
            lonData.Dimension = {'longitude'};
            nc_addvar(newFile,lonData);

            % Writing the data into file
            nc_varput(newFile,'latitude',latDataSet);
            nc_varput(newFile,'longitude',lonDataSet);
        end
        for i=1:1:length(latDataSet)
            for j=1:1:length(lonDataSet)
                meanOut(m,i,j) = mean(timeDataSet(fPos:lPos,i,j)); %#ok<AGROW>
            end
            if isequal(mod(i,50),1)
                perc = 100*(i*length(lonDataSet)/(length(lonDataSet)*length(latDataSet)));%(length(latDataSet)-i+1)*length(lonDataSet);
                waitbar(perc/100,h,strcat(monthsName(m),sprintf(' data written %d%% along...',round(perc))));
                %waitbar(perc/100,h,sprintf('Data written %d%% along...',round(perc)));
            end
        end
        % Writing the data into file
        nc_varput(newFile,var2Read,meanOut);
        waitbar(1,h,strcat(monthsName(m),' data saved.'));
        disp(strcat('Data saved:  ',monthsName(m),' - ',num2str(yearC),' - Days: ',num2str(fPos),' - ',num2str(lPos)));
    end
    close(h);
end
