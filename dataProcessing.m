% Function dataProcessing
%
% Prototype: dataProcessing(dirName,var2Read,yearZero,yearN)
%            dataProcessing(dirName,var2Read)
%            dataProcessing(dirName)
%
% dirName = Path of the directory that contents the files and path for the
% processing files
% var2Read (Recommended)= Variable to be read (use 'ncdump' to check variable names)
% yearZero (Optional) = Lower year of the data to be read
% yearN (Optional) = Higher year of the data to be read
function [] = dataProcessing(dirName,var2Read,yearZero,yearN)
    if nargin < 1
        error('dataProcessing: dirName is a required input')
    else
        dirName = strrep(dirName,'\','/'); % Clean dirName var
    end
    if nargin < 2 % Validates if the var2Read param is received
        temp = java.lang.String(dirName(1)).split('/');
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
    dirData = dir(char(dirName(1)));  % Get the data for the current directory
    months = [31,28,31,30,31,30,31,31,30,31,30,31]; % Reference to the number of days per month
    monthsName = {'January','February','March','April','May','June','July','August','September','October','November','December'};
    path = java.lang.String(dirName(1));
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    if(length(dirName)>1)
        save_path = java.lang.String(dirName(2));
        if(length(dirName)>2)
            path_log = java.lang.String(dirName(3));
        else
            path_log = java.lang.String(dirName(2));
        end
	else
		save_path = java.lang.String(dirName(1));
		path_log = java.lang.String(dirName(1));
    end
	if(save_path.charAt(save_path.length-1) ~= '/')
		save_path = save_path.concat('/');
	end
	if(path_log.charAt(path_log.length-1) ~= '/')
		path_log = path_log.concat('/');
	end
    for f = 3:length(dirData)
        fileT = path.concat(dirData(f).name);
        if(fileT.substring(fileT.lastIndexOf('.')+1).equalsIgnoreCase('nc'))
            try
                yearC = str2double(fileT.substring(fileT.length-7,fileT.lastIndexOf('.')));
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
                    writeFile(fileT,var2Read,yearC,months,save_path,monthsName,path_log);
                end
            catch
                continue;
            end
        else
            if isequal(dirData(f).isdir,1)
                  newPath = char(path.concat(dirData(f).name));
                if nargin < 2 % Validates if the var2Read param is received
                    dataProcessing({newPath,char(save_path.concat(dirData(f).name)),char(path_log)});
                elseif nargin < 3 % Validates if the yearZero param is received
                    dataProcessing({newPath,char(save_path.concat(dirData(f).name)),char(path_log)},var2Read);
                elseif nargin < 4 % Validates if the yearN param is received
                    dataProcessing({newPath,char(save_path.concat(dirData(f).name)),char(path_log)},var2Read,yearZero)
                else
                    dataProcessing({newPath,char(save_path.concat(dirData(f).name)),char(path_log)},var2Read,yearZero,yearN)
                end
            end
        end
    end
end

function [] = writeFile(fileT,var2Read,yearC,months,path,monthsName,path_log)
    % Catching data from original file
    latDataSet = ncread(char(fileT),'lat'); 
    lonDataSet = ncread(char(fileT),'lon');
    try
        timeDataSet = ncread(char(fileT),var2Read);
    catch exception
        out = [];
        fid = fopen(strcat(char(logPath),'log.txt'), 'at');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
        fclose(fid);
        disp(exception.message);
    end
    lPos = 0;
    %newName = strcat('[CIGEFI] ',num2str(yearC),'.nc');
    newName = strcat(num2str(yearC),'.nc');
    meanOut = [];
    for m=1:1:length(months)
        fPos = lPos + 1;
        if(leapyear(yearC)&& m ==2 && length(timeDataSet(:,1,1))==366)
            lPos = months(m) + fPos; % Leap year
        else
            lPos = months(m) + fPos - 1;
        end
        if(m==1) % New file configuration
            if ~exist(char(path),'dir')
                mkdir(char(path));
            end
            newFile = char(path.concat(newName));
            nc_create_empty(newFile,'netcdf4-classic');

            % Adding file dimensions
            nc_add_dimension(newFile,'lat',length(latDataSet));
            nc_add_dimension(newFile,'lon',length(lonDataSet));
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
            nc_attput(newFile,nc_global,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
            nc_attput(newFile,nc_global,'data_analysis_date',char(datetime('today')));
            nc_attput(newFile,nc_global,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

            % Adding file variables
            monthlyData.Name = var2Read;
            monthlyData.Datatype = 'single';
            monthlyData.Dimension = {'time','lat', 'lon'};
            nc_addvar(newFile,monthlyData);

            timeData.Name = 'time';
            timeData.Dimension = {'time'};
            nc_addvar(newFile,timeData);

            latData.Name = 'lat';
            latData.Dimension = {'lat'};
            nc_addvar(newFile,latData);

            lonData.Name = 'lon';
            lonData.Dimension = {'lon'};
            nc_addvar(newFile,lonData);

            % Writing the data into file
            nc_varput(newFile,'lat',latDataSet);
            nc_varput(newFile,'lon',lonDataSet);
        end
        meanOut = cat(1,meanOut,mean(timeDataSet(fPos:lPos,:,:),1));
        %disp(strcat({'Data saved:  '},monthsName(m),{' - '},num2str(yearC),{' - Days: '},num2str(fPos),{' - '},num2str(lPos)));
    end
    try
    	clear timeDataSet;
    	% Writing the data into file
    	nc_varput(newFile,var2Read,meanOut);
    	fid = fopen(strcat(char(path_log),'log.txt'), 'at');
    	fprintf(fid, '%s\n',char(fileT));
    	fclose(fid);
    	disp(strcat({'Data saved:  '},num2str(yearC)));
    catch exception
        out = [];
        fid = fopen(strcat(char(logPath),'log.txt'), 'at');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
        fclose(fid);
        disp(exception.message);
    end
end
