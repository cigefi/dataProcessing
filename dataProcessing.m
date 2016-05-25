% Function dataProcessing
%
% Prototype: dataProcessing(dirName,var2Read,yearZero,yearN)
%            dataProcessing(dirName,var2Read)
%            dataProcessing(dirName)
%
% dirName = Path of the directory that contents the files and destiny path for the
% processing files (cell array)
% var2Read (Recommended)= Variable to be read (use 'ncdump' to check variable names)
% yearZero (Optional) = Lower year of the data to be read
% yearN (Optional) = Higher year of the data to be read
function [] = dataProcessing(dirName,var2Read,yearZero,yearN)
    if nargin < 1
        error('dataProcessing: dirName is a required input');
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
    %monthsName = {'January','February','March','April','May','June','July','August','September','October','November','December'};
    path = java.lang.String(dirName(1));
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    try
        experimentParent = path.substring(0,path.lastIndexOf(strcat('/',var2Read)));
        experimentName = experimentParent.substring(experimentParent.lastIndexOf('/')+1);
    catch
        experimentName = '[CIGEFI]'; % Dafault value
    end
    if(length(dirName)>1)
        savePath = java.lang.String(dirName(2));
        if(length(dirName)>2)
            logPath = java.lang.String(dirName(3));
        else
            logPath = java.lang.String(dirName(2));
        end
	else
		savePath = java.lang.String(dirName(1));
		logPath = java.lang.String(dirName(1));
    end
    if(savePath.charAt(savePath.length-1) ~= '/')
        savePath = savePath.concat('/');
    end
    if(logPath.charAt(logPath.length-1) ~= '/')
        logPath = logPath.concat('/');
    end
    processing = 0;
    out = [];
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
                %if(yearC > 0)
                 if all(yearC > 0 && ~strcmp(experimentName,'[CIGEFI]'))
                    if(~processing)
                        fprintf('Processing: %s\n',char(experimentName));
                        processing = 1;
                        if ~exist(char(logPath),'dir')
                            mkdir(char(logPath));
                        end
                        if(exist(strcat(char(logPath),'log.txt'),'file'))
                            delete(strcat(char(logPath),'log.txt'));
                        end
                    end
                    % Subrutine to writte the data in new Netcdf file
                    [nr,newFile] = writeFile(fileT,var2Read,yearC,months,savePath,logPath,char(experimentName));
                    if isempty(out)
                        out = nr;
                    else
                        out = nanmean(cat(1,out,nr),1);
                    end
                end
            catch %e
                %disp(e.message);
            	continue;
            end
        else
            if ~isempty(out)
                try
                    ncid = netcdf.open(char(newFile));
                    varID = netcdf.inqVarID(ncid,var2Read);
                    % Writing the data into file
                    netcdf.putVar(ncid,varID,[0 0 0],[length(out(:,1,1)) length(out(1,:,1)) length(out(1,1,:))],out);
                    netcdf.close(ncid);
                catch exception
                    if(exist(char(logPath),'dir'))
                        fid = fopen(strcat(char(logPath),'log.txt'), 'at+');
                        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
                        fclose(fid);
                    end
                    mailError(type,var2Read,char(experimentName),char(exception.message));
                    continue;
                end
            end
            if isequal(dirData(f).isdir,1)
                newPath = char(path.concat(dirData(f).name));
                if nargin < 2 % Validates if the var2Read param is received
                    dataProcessing({newPath,char(savePath.concat(dirData(f).name)),char(logPath)});
                elseif nargin < 3 % Validates if the yearZero param is received
                    dataProcessing({newPath,char(savePath.concat(dirData(f).name)),char(logPath)},var2Read);
                elseif nargin < 4 % Validates if the yearN param is received
                    dataProcessing({newPath,char(savePath.concat(dirData(f).name)),char(logPath)},var2Read,yearZero)
                else
                    dataProcessing({newPath,char(savePath.concat(dirData(f).name)),char(logPath)},var2Read,yearZero,yearN)
                end
            end
        end
    end
end

function [meanOut,newFile] = writeFile(fileT,var2Read,yearC,months,path,logPath,experimentName)
    newName = strcat(experimentName,'.nc');
    newFile = char(path.concat(newName));
    meanOut = [];
    if exist(newFile,'file')
        try
            fid = fopen(strcat(char(logPath),'log.txt'), 'at');
            fprintf(fid, '[EXIST] %s\n',char(fileT));
            fclose(fid);
            disp(char(strcat(num2str(yearC),{' '},'file already exists')));
            return;
        catch exception
            fid = fopen(strcat(char(logPath),'log.txt'), 'at');
            fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
            fclose(fid);
            disp(exception.message);
        end
    end
    [latDataSet,err] = readNC(fileT,'lat');
    if ~isnan(err)
        fid = fopen(strcat(char(logPath),'log.txt'), 'at+');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
        fclose(fid);
        return;
    end
    
    [lonDataSet,err] = readNC(fileT,'lon');
    if ~isnan(err)
        fid = fopen(strcat(char(logPath),'log.txt'), 'at+');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
        fclose(fid);
        return;
    end
    [timeDataSet,err] = readNC(fileT,var2Read);
    if ~isnan(err)
        fid = fopen(strcat(char(logPath),'log.txt'), 'at+');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
        fclose(fid);
        return;
    end
    lPos = 0;
    %newName = strcat('[CIGEFI] ',num2str(yearC),'.nc');

    meanOut = [];
    for m=1:1:12
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

            try
                % Catching data from original file
                ncoid = netcdf.open(char(fileT));
                GLOBALNC = netcdf.getConstant('NC_GLOBAL');
                
                % Creating new nc file
                if exist(newFile,'file')
                    delete(newFile);
                end
                ncid = netcdf.create(newFile,'NETCDF4');%nc_create_empty(newFile,'netcdf4');

                % Adding file dimensions
                latdimID = netcdf.defDim(ncid,'lat',length(latDataSet));
                londimID = netcdf.defDim(ncid,'lon',length(lonDataSet));
                timedimID = netcdf.defDim(ncid,'time',netcdf.getConstant('NC_UNLIMITED'));

                % Global params
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment_id',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment_rip',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'institution',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'realm',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'modeling_realm',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'version',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'downscalingModel',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'experiment_id',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
                netcdf.putAtt(ncid,GLOBALNC,'frequency','monthly');
                netcdf.putAtt(ncid,GLOBALNC,'year',num2str(yearC));
                netcdf.putAtt(ncid,GLOBALNC,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
                netcdf.putAtt(ncid,GLOBALNC,'data_analysis_institution',char(datetime('today')));
                netcdf.putAtt(ncid,GLOBALNC,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');
                
                % Adding file variables
                monthlyvarID = netcdf.defVar(ncid,var2Read,'float',[timedimID,latdimID,londimID]);
                [~] = netcdf.defVar(ncid,'time','float',timedimID);
                latvarID = netcdf.defVar(ncid,'lat','float',latdimID);
                lonvarID = netcdf.defVar(ncid,'lon','float',londimID);

                netcdf.endDef(ncid);
                % Writing the data into file
                netcdf.putVar(ncid,latvarID,latDataSet);
                netcdf.putVar(ncid,lonvarID,lonDataSet);
            catch exception
                disp(exception.message);
                netcdf.close(ncid);
                netcdf.close(ncoid);
                if exist(newFile,'file')
                    delete(newFile);
                end
                fid = fopen(strcat(char(logPath),'log.txt'), 'at');
                fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
                fclose(fid);
                return;
            end
        end
        meanOut = cat(1,meanOut,nanmean(timeDataSet(fPos:lPos,:,:),1));
    end
    try
    	clear timeDataSet;
%     	%Writing the data into file
%         netcdf.putVar(ncid,monthlyvarID,[0 0 0],[12 length(latDataSet) length(lonDataSet)],meanOut);
        netcdf.close(ncid);
        netcdf.close(ncoid);
    	fid = fopen(strcat(char(logPath),'log.txt'), 'at');
    	fprintf(fid, '[SAVED][%s] %s\n',char(datetime('now')),char(fileT));
    	fclose(fid);
    	disp(char(strcat({'Data saved:  '},num2str(yearC))));
    catch exception
        fid = fopen(strcat(char(logPath),'log.txt'), 'at');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
        fclose(fid);
        disp(exception.message);
    end
end

function [data,error] = readNC(path,var2Read)
    var2Readid = 99999;
	error = NaN;
    try
        % Catching data from original file
        ncid = netcdf.open(char(path));
        [~,nvar,~,~] = netcdf.inq(ncid);
        for i=0:1:nvar-1
            [varname,~,~,~] = netcdf.inqVar(ncid,i);
            switch(varname)
                case var2Read
                    var2Readid = i;
                    break;
            end
        end
        data = netcdf.getVar(ncid,var2Readid,'double');
        if strcmp(var2Read,'lon') 
            data = data';
        elseif ~strcmp(var2Read,'lat')
            data = permute(data,[3 2 1]);
        end
        if isempty(data)
            error = 'Empty dataset';
        end
        netcdf.close(ncid)
    catch exception
        data = [];
        try
            netcdf.close(ncid)
        catch
            error = 'I/O ERROR';
            return;
        end
        error = exception.message;
    end
end

function [] = mailError(type,var2Read,experimentName,msg)
    RECIPIENTS = {'villegas.roberto@hotmail.com'};
    subject = strcat({'[MATLAB][ERROR] '},type,{' - '},var2Read,{' - '},experimentName);
    msj = strcat({'An exception has been thrown: '},msg);
    mailsender(RECIPIENTS,subject,msj);
end