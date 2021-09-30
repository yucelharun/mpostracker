% This code is written by Harun, 2021
classdef mPosTracker < handle
    properties
        ProjectName = ''; %Project name
        save_project_path = ''; %Saved project path name
        save_project_file = ''; %Saved project file name
        save_project_l = 0; %Logical about saving project
        recalculation_l = 0; %Logical about requiring recalculation
        reclassification = 0; %Logical about reclassifying
        
        coll = [[1 0 0]; [0 1 0]; [0 0 1]]; %Color codes RGB
        RecPar = [20, 20, 20]; %Particle sing rectangle size
        current_index = 0; %Current index of video frames
        vid_filename = ''; %Video file name
        vid_pathname = ''; %Video path name
        ColorMod = 0; %Video color mode
        video = 0; 
        video_l = 0; %Logical about loading  a video
        UserSize = [0, 0 ,0 ,0]; %resizing of frame
        frame = 0; 
        invertedim = 0; %Logical about inverted video frame
        imFull = 0; %Last Readed frame
        imFull_fft = 0; %FFT of last readed frame
        CamSize = 0; %Frame size of video
        nFrame = 0; %Total frame number
        FrameRate = 0; %Frame rate
        Channel = 1; %Color channel
        
        Start_i = 1; %Selected starting frame number
        End_i = 0; %Selected ending frame number
        Step_i = 1; %Selected step number
        TimeSer = 0; %Time series
        FrameN = 0; %Frame number series
        pix2mic = 1; %Conversation parameter pixel to micron
       
        FramePos %Class for PosTracker
        FramePos_l = 0; %Logical
        CalcMethod = 1; %Selected calculation method
        th = 128; %Selected thereshol parameter
        Rout = 0; %Selected Rout parameter for CalcMod = 3
        RedArea = 0; %Ignored area size for side of frames
        
        StepLength = 15; %Maximum  travel length
        GreenArea = 0; %Relabeling area size
        BlueArea = 0; %Relabeling area size
        AllowNewLabelGreen = 1; %Logical for relabeling
        AllowNewLabelBlue = 0; %Logical for relabeling
        
        
        centers = 0; %Center coordinates
        nelements = 0; % Distribution
        datatur = 0; %Classification type parameter
        
        fitt = 0; %Gaussian fiting
        fitpar = 0; %Gaussian fiting
        fit_l = 0; %Gaussian fitging
        
        limits = [0,0;0,0;0,0]; %Boundery parameters for classification
        tursay = 1; %Type parameter
        turpar = 0; %Type for classification presedure
        
        LabelNum = 0; %Label number
        ParSay = 0; %Particles number
        partnum = 0; %Total particle number
        HamData = []; %Position data for not classifying results
        classdata = []; %Position data for classifying results
        ClassDataMic = []; %Calibrated Position data for classifying results
        
        classdata_filename = ''; %Classified data file name if saved
        classdata_pathname = ''; %Classified data path name if saved
        hamdata_filename = ''; %Not Classified data file name if saved
        hamdata_pathname = ''; %Not Classified data path name if saved
        save_classdata_l = 0; %Logical for saving classified data
        save_hamdata_l = 0; %Logical for saving not classified data
        
        panel_l = 0; %Logical for graphical results for commond line version
        show_HamData = 0; %Logical for graphical results for commond line version
        show_Num = 0; %Logical for graphical results for commond line version
        show_borders = 0; %Logical for graphical results for commond line version
        show_ident_trac = 0; %Logical for graphical results for commond line version
        show_trajectories = 0; %Logical for graphical results for commond line version
        show_labels = 0; %Logical for graphical results for commond line version
        show_mask = 0; %Logical for graphical results for commond line version
    end
    methods 
        function obj = mPosTracker() %Main function
            
        end
        function addVideo(obj,  PathName, FileName) %Loading a new video
            obj.vid_filename = FileName;
            obj.vid_pathname = PathName;
            obj.video = VideoReader([obj.vid_pathname obj.vid_filename]);
            obj.nFrame = obj.video.NumberOfFrames;
            obj.FrameRate = obj.video.FrameRate;
            obj.video_l = 1;
            obj.HamData.Par = [];
            obj.LabelNum = 0;
            obj.ParSay = 0;
            obj.partnum = 0;
            obj.HamData = [];
            obj.classdata = [];
            obj.ClassDataMic = [];
            format = obj.video.videoFormat;
            switch format
                case {'Mono8', 'Mono8 Signed', 'Mono16', 'Mono16 Signed'}
                    obj.ColorMod = 0;
                case {'RGB24','RGB24 Signed','RGB48','RGB48 Signed'}
                    obj.ColorMod = 1;
                otherwise
            end
            obj.Channel = 1;
            obj.Prepare;
            obj.current_index = 1;
            obj.takeim(obj.current_index);
            obj.UserSize = [1, obj.video.height, 1, obj.video.width];
            obj.setAreas();
        end
        function setAreas(obj) %Setting user defined size for frames
            if floor(abs(obj.UserSize(1) - obj.UserSize(2)-1)*0.1) ...
             <= floor(abs(obj.UserSize(3) - obj.UserSize(4)-1)*0.1)
                obj.RedArea = floor(abs(obj.UserSize(1) - obj.UserSize(2)-1)*0.1);
            else
                obj.RedArea = floor(abs(obj.UserSize(3) - obj.UserSize(4)-1)*0.1);
            end
            obj.GreenArea = floor(obj.RedArea*1.2);
            obj.BlueArea = floor(obj.RedArea*1.4);            
        end
        function start(obj) %Starting commond for finding positions for loop
            obj.Prepare;
            for i = 1:length(obj.FrameN)
                obj.Calc(i);
                obj.Disp_Time(i,length(obj.FrameN));
                if obj.panel_l == 1
                    obj.Show_Panel(obj.FrameN(obj.current_index),obj.FrameN(length(obj.FrameN)));
                end
            end
        end
        function Calc(obj,i) %Main for finding position for loop
            obj.takeim(i);
            obj.FramePos = PosFinder(obj.imFull,obj.th,obj.RedArea,obj.CalcMethod,obj.Rout);
            obj.HamData(obj.current_index).Par = [obj.FramePos.dCent, obj.FramePos.tA, obj.FramePos.tI];
            obj.partnum(obj.current_index) = obj.FramePos.partnum;
        end
        function Calc_Pos(obj,i) %Main for finding position for GUI loop
            obj.takeim(i);
            obj.FramePos = PosFinder(obj.imFull,obj.th,obj.RedArea,obj.CalcMethod,obj.Rout);
        end
        function Classify(obj) %Classifying command
            obj.classdata = []; obj.ClassDataMic = [];
            for i = 1:length(obj.FrameN)

                obj.TimeSeries(i);

            end
        end
        function Show_Results(obj) %Show results for commond line version
            for i = 1:length(obj.FrameN)
                if obj.panel_l == 1
                    obj.takeim(i);
                    obj.Show_Panel(obj.FrameN(obj.current_index),obj.FrameN(length(obj.FrameN)));
                end
            end
        end
        function Prepare(obj) %Prerape Time Series
            if obj.End_i == 0
                obj.End_i = obj.nFrame;
            end
            if obj.Step_i <= 0 && obj.Step_i > obj.End_i
                obj.Step_i = 1;
            end
            obj.FrameN = obj.Start_i : obj.Step_i : obj.End_i;
            obj.FrameRate = obj.video.FrameRate;
            obj.TimeSer = obj.Step_i*(1/obj.FrameRate*1000)*(0:length(obj.FrameN)-1); %in milisecond
        end
        function c = checkHamData(obj) %Checking for having non classified data
            c = 0;
            num = numel(obj.HamData);
            if num == length(obj.FrameN)
                c = 1;
            end
        end
        function c = checkClassData(obj) %Checking for having classified data
            c = 0;
            num = numel(obj.classdata);
            if num == obj.tursay
                num = numel(obj.classdata(num).Par(1).Data(:,1));
                if num == length(obj.FrameN)
                    c = 1;
                end
            end
        end
        function c = isexistvideo(obj) %Checking for having loaded video
            if obj.video_l == 0
                c = 0;
            else
                c = 1;
            end
        end
        function saveHamData (obj, PathName, FileName) %Saving for non classified data
            if obj.checkHamData == 1
                if ischar(FileName)
                    d = obj.HamData;
                    save([PathName FileName],'d');
                    obj.hamdata_filename = FileName;
                    obj.hamdata_pathname = PathName;
                    obj.save_hamdata_l = 1;
                end
            end
        end
        function saveClassData (obj,  PathName, FileName) %Saving for classified data
            if obj.checkClassData == 1
                if ischar(FileName)
                    d = obj.classdata;
                    save([PathName FileName],'d');
                    obj.classdata_filename = FileName;
                    obj.classdata_pathname = PathName;
                    obj.save_classdata_l = 1;
                end
            end
        end
        function saveProject(obj, PathName, FileName) %Saving for project
            ss = struct(...
                        'A0',obj.current_index,...
                        'A1',obj.vid_filename,...
                        'A2',obj.vid_pathname,...
                        'A3',obj.ColorMod,...
                        'A4',obj.video_l,...
                        'A5',obj.UserSize,...
                        'A6',obj.frame,...
                        'A7',obj.invertedim,...
                        'A8',obj.imFull,...
                        'A9',obj.CamSize,...
                        'A10',obj.nFrame,...
                        'A11',obj.FrameRate,...
                        'A12',obj.Channel,...
                        'A13',obj.Start_i,...
                        'A14',obj.End_i,...
                        'A15',obj.TimeSer,...
                        'A16',obj.FrameN,...
                        'A17',obj.CalcMethod,...
                        'A18',obj.datatur,...
                        'A19',obj.th,...
                        'A20',obj.Rout,...
                        'A21',obj.RedArea,...
                        'A22',obj.StepLength,...
                        'A23',obj.GreenArea,...
                        'A24',obj.BlueArea,...
                        'A25',obj.AllowNewLabelGreen,...
                        'A26',obj.AllowNewLabelBlue,...
                        'A27',obj.centers,...
                        'A28',obj.nelements,...
                        'A29',obj.fitpar,...
                        'A30',obj.limits,...
                        'A31',obj.tursay,...
                        'A32',obj.turpar,...
                        'A33',obj.LabelNum,...
                        'A34',obj.ParSay,...
                        'A35',obj.partnum,...
                        'A36',obj.HamData,...
                        'A37',obj.classdata,...
                        'A38',obj.classdata_filename,...
                        'A39',obj.classdata_pathname,...
                        'A40',obj.hamdata_filename,...
                        'A41',obj.hamdata_pathname,...
                        'A42',obj.save_classdata_l,...
                        'A43',obj.save_hamdata_l,...
                        'A44',obj.panel_l,...
                        'A45',obj.show_HamData,...
                        'A46',obj.show_Num,...
                        'A47',obj.show_borders,...
                        'A48',obj.show_ident_trac,...
                        'A49',obj.show_trajectories,...
                        'A50',obj.show_labels,...
                        'A51',obj.show_mask,...
                        'A52',obj.fitt,...
                        'A53',obj.fit_l,...
                        'A54',obj.ProjectName,...
                        'A55',obj.save_project_path,...
                        'A56',obj.save_project_file,...
                        'A57',obj.recalculation_l,...
                        'A58',obj.reclassification,...
                        'A59',obj.RecPar,...
                        'A60',obj.ClassDataMic);
            save([PathName FileName], 'ss','-mat');
        end
        function readProject(obj, PathName, FileName) %Loading previously saved project
            ss = load([PathName FileName],'-mat');
            ss = ss.ss;
                    obj.current_index = ss.A0;
                    obj.vid_filename = ss.A1;
                    obj.vid_pathname = ss.A2;
                    obj.ColorMod = ss.A3;
                    obj.video_l = ss.A4;
                    obj.UserSize = ss.A5;
                    obj.frame = ss.A6;
                    obj.invertedim = ss.A7;
                    obj.imFull = ss.A8;
                    obj.CamSize = ss.A9;
                    obj.nFrame = ss.A10;
                    obj.FrameRate = ss.A11;
                    obj.Channel = ss.A12;
                    obj.Start_i = ss.A13;
                    obj.End_i = ss.A14;
                    obj.TimeSer = ss.A15;
                    obj.FrameN = ss.A16;
                    obj.CalcMethod = ss.A17;
                    obj.datatur = ss.A18;
                    obj.th = ss.A19;
                    obj.Rout = ss.A20;
                    obj.RedArea = ss.A21;
                    obj.StepLength = ss.A22;
                    obj.GreenArea = ss.A23;
                    obj.BlueArea = ss.A24;
                    obj.AllowNewLabelGreen = ss.A25;
                    obj.AllowNewLabelBlue = ss.A26;
                    obj.centers = ss.A27;
                    obj.nelements = ss.A28;
                    obj.fitpar = ss.A29;
                    obj.limits = ss.A30;
                    obj.tursay = ss.A31;
                    obj.turpar = ss.A32;
                    obj.LabelNum = ss.A33;
                    obj.ParSay = ss.A34;
                    obj.partnum = ss.A35;
                    obj.HamData = ss.A36;
                    obj.classdata = ss.A37;
                    obj.classdata_filename = ss.A38;
                    obj.classdata_pathname = ss.A39;
                    obj.hamdata_filename = ss.A40;
                    obj.hamdata_pathname = ss.A41;
                    obj.save_classdata_l = ss.A42;
                    obj.save_hamdata_l = ss.A43;
                    obj.panel_l = ss.A44;
                    obj.show_HamData = ss.A45;
                    obj.show_Num = ss.A46;
                    obj.show_borders = ss.A47;
                    obj.show_ident_trac = ss.A48;
                    obj.show_trajectories = ss.A49;
                    obj.show_labels = ss.A50;
                    obj.show_mask = ss.A51;
                    obj.fitt =  ss.A52;
                    obj.fit_l = ss.A53;
                    obj.ProjectName = ss.A54;
                    obj.save_project_path = ss.A55;
                    obj.save_project_file = ss.A56;
                    obj.recalculation_l = ss.A57;
                    obj.reclassification = ss.A58;
                    obj.RecPar = ss.A59;
                    obj.ClassDataMic = ss.A60;
            if exist([obj.vid_pathname obj.vid_filename], 'file') > 0
                obj.video = VideoReader([obj.vid_pathname obj.vid_filename]);
                obj.video_l = 1;
            else
                obj.video_l = 0;
            end
                    
        end
        function TimeSeries(obj, tN) %Storing results
             if tN == 1
                for i = 1 : obj.tursay
                    n(i) = 0;
                    Par.Data = [];
                    Tur(i).Par=Par;
                    obj.ParSay = zeros(1,obj.tursay+1);
                end
            else
                n = obj.LabelNum;
                Tur = obj.classdata;
                obj.ParSay = [obj.ParSay; zeros(1,obj.tursay+1)];
            end
            
            for k1 = 1 : obj.tursay
                for k2 = 1 : length(Tur(k1).Par)
                 Tur(k1).Par(k2).Data = [Tur(k1).Par(k2).Data;[obj.TimeSer(tN), NaN, NaN, NaN]];
                end
            end
            
            obj.ParSay(tN, 1) = obj.TimeSer(tN);

            for k = 1 : obj.partnum(tN)
                if obj.turpar ~= 0
                    turindex = obj.identpar(tN, k);
                else
                    turindex = 1;
                end
%                 obj.ParSay(tN, 1) = obj.TimeSer(tN);
                x2 = obj.HamData(tN).Par(k,1);
                y2 = obj.HamData(tN).Par(k,2);
                 A = obj.HamData(tN).Par(k,3);
                
                if turindex ~= 0
                if tN == 1
                    if ((x2 > obj.GreenArea) && (x2 < obj.CamSize(2)-obj.GreenArea) && (y2 > obj.GreenArea) && (y2 < obj.CamSize(1)-obj.GreenArea))
                        n(turindex) = n(turindex) +1;
                        Tur(turindex).Par(n(turindex)).Data = [obj.TimeSer(tN), x2, y2, A];                
                        obj.ParSay(tN,turindex + 1) = obj.ParSay(tN,turindex + 1) + 1;
                    end
                else
                    traindex = obj.bul(x2, y2, turindex);
                    if traindex ~= 0
%                         Tur(turindex).Par(traindex).Data = [Tur(turindex).Par(traindex).Data;[obj.TimeSer(tN), x2, y2]];
                        Tur(turindex).Par(traindex).Data(tN,:) = [obj.TimeSer(tN), x2, y2, A];
                        obj.ParSay(tN,turindex + 1) = obj.ParSay(tN,turindex + 1) + 1;
                    else
                        if obj.AllowNewLabelGreen == 1
                            if obj.AllowNewLabelBlue == 1
                                if (x2 > obj.GreenArea) && (x2 < obj.CamSize(2)-obj.GreenArea) && (y2 > obj.GreenArea) && (y2 < obj.CamSize(1)-obj.GreenArea)
                                        n(turindex) = n(turindex) +1;
                                        Tur(turindex).Par(n(turindex)).Data = [obj.TimeSer(1:tN-1)', NaN*ones(tN-1,1), NaN*ones(tN-1,1), NaN*ones(tN-1,1)];
                                        Tur(turindex).Par(n(turindex)).Data = [Tur(turindex).Par(n(turindex)).Data; [obj.TimeSer(tN), x2, y2, A]];
                                        obj.ParSay(tN,turindex + 1) = obj.ParSay(tN,turindex + 1) + 1;
                                end
                            else
                                if xor(((x2 > obj.GreenArea) && (x2 < obj.CamSize(2)-obj.GreenArea) && (y2 > obj.GreenArea) && (y2 < obj.CamSize(1)-obj.GreenArea))...
                                         , ((x2 > obj.BlueArea) && (x2 < obj.CamSize(2)-obj.BlueArea) && (y2 > obj.BlueArea) && (y2 < obj.CamSize(1)-obj.BlueArea)))
                                        n(turindex) = n(turindex) +1;
                                        Tur(turindex).Par(n(turindex)).Data = [obj.TimeSer(1:tN-1)', NaN*ones(tN-1,1), NaN*ones(tN-1,1), NaN*ones(tN-1,1)];
                                        Tur(turindex).Par(n(turindex)).Data = [Tur(turindex).Par(n(turindex)).Data; [obj.TimeSer(tN), x2, y2, A]];
                                        obj.ParSay(tN,turindex + 1) = obj.ParSay(tN,turindex + 1) + 1;
                                end
                            end
                        end
                    end
                    
                end
                end
            
            end
            
            obj.classdata = Tur;
            obj.ClassDataMic = Tur;
            obj.LabelNum = n;
            
            for k = 1 : obj.tursay
                for k2 = 1 : numel(obj.classdata(k).Par)
                    obj.ClassDataMic(k).Par(k2).Data = obj.classdata(k).Par(k2).Data*obj.pix2mic;
                end
            end
            
        end
        function Disp_Time(obj,n,maxn) %Displaying time
            disp([num2str(n) 'th Frame, ' num2str(n/maxn*100) '%, Elapsed time is ' num2str(obj.FramePos.caltime)]);
        end
        function Show_Panel(obj, n, maxn) %Showing panel for graphical results
            if obj.show_mask == 1
                image(obj.imFull+obj.FramePos.mask*50), colormap(gray(256))
            else
                image(obj.imFull), colormap(gray(256))
            end
            hold on
            if obj.show_borders == 1
                rectangle('Position',[obj.RedArea, obj.RedArea, obj.CamSize(2)-2*obj.RedArea, obj.CamSize(1)-2*obj.RedArea],'EdgeColor','r')
                rectangle('Position',[obj.GreenArea, obj.GreenArea, obj.CamSize(2)-2*obj.GreenArea, obj.CamSize(1)-2*obj.GreenArea],'EdgeColor','g')
                rectangle('Position',[obj.BlueArea, obj.BlueArea, obj.CamSize(2)-2*obj.BlueArea, obj.CamSize(1)-2*obj.BlueArea],'EdgeColor','b')
            end
            if obj.show_HamData == 1
                plot(obj.HamData(n).Par(:,1),obj.HamData(n).Par(:,2),'ok')
            end
            px = 0.1*obj.CamSize(2);%max(get(gca,'XTick'));
            py = 0.1*obj.CamSize(1);%max(get(gca,'YTick'));

            if obj.checkClassData == 1
                for k = 1 : obj.tursay
                    for k2 = 1 : numel(obj.classdata(k).Par)
                        if obj.show_Num == 1
                        text((10-k)*px,9*py,num2str(obj.ParSay(n,k+1)),'color',obj.coll(k,:),'background','k','FontSize',18)
                        end
    %                     if obj.show_ident_trac == 1
                            plot(obj.classdata(k).Par(k2).Data(n,2),obj.classdata(k).Par(k2).Data(n,3),'.','color',obj.coll(k,:))
    %                     end
                        if obj.show_trajectories == 1
                            plot(obj.classdata(k).Par(k2).Data(1:n,2),obj.classdata(k).Par(k2).Data(1:n,3),'-','color',obj.coll(k,:))
                        end
                        if obj.show_labels == 1
                            for l = 1:k2
                            text(obj.classdata(k).Par(l).Data(n,2),obj.classdata(k).Par(l).Data(n,3),num2str(l),'color',obj.coll(k,:),'FontSize',18,'background','k')
                            end
                        end                    
                    end
                end
            end
            if obj.show_Num == 1
                text(px,py,[num2str(n) '/' num2str(maxn)],'color','w','background','k','FontSize',18)
            end
            axis equal
            hold off
            drawnow;
        end
        function traindex = bul(obj, x2, y2, tur) %Storing results
            partN = numel(obj.classdata(tur).Par);
            traindex = 0;
            for i = 1 : partN
                x1 = obj.classdata(tur).Par(i).Data(end,2);
                y1 = obj.classdata(tur).Par(i).Data(end,3);
                r = sqrt((x1-x2)^2+(y1-y2)^2);
                if r <= obj.StepLength
                    traindex = i;
                end
             end
        end
        function turindex = identpar(obj,tN,k) %Storing results
            turindex = 0;
            switch obj.turpar
                case 0

                case 1
                    dizi = obj.HamData(tN).Par(:,3);
                case 2 
                    dizi = obj.HamData(tN).Par(:,4);
                otherwise
                    error('turpar is wrong')
            end
            if obj.turpar ~= 0
                for i = 1 : obj.tursay
                    if dizi(k)>=obj.limits(i,1) && dizi(k)<=obj.limits(i,2)
                        turindex = i;
                    end
                end
            end
        end
        function takeim(obj,i) %Reading image from video frame
            obj.current_index = i;
            obj.frame = read(obj.video,obj.FrameN(obj.current_index));
            ss = size(obj.frame);
            if length(ss) > 2
                im=double(obj.frame(:,:,obj.Channel));
            else
                im=double(obj.frame(:,:));
            end

            if length(obj.UserSize) == 4
                if obj.UserSize(1) ~= 0 && obj.UserSize(2) ~= 0 && obj.UserSize(3) ~= 0 && obj.UserSize(4) ~= 0
                    im=double(im(obj.UserSize(1):obj.UserSize(2),obj.UserSize(3):obj.UserSize(4)));
                end
            end
            
            if obj.invertedim == 1
                im = 255-im;
            end
            
            h = ones(3)/9;
            im = conv2(im/255, h, 'same')*255;
            
            obj.imFull = im;
            obj.CamSize = size(im);
        end
        function takeim_fft(obj,i) %Reading image from video frame for FFT
            obj.current_index = i;
            obj.frame = read(obj.video,obj.FrameN(obj.current_index));
            ss = size(obj.frame);
            if length(ss) > 2
                im=double(obj.frame(:,:,obj.Channel));
            else
                im=double(obj.frame(:,:));
            end

            if length(obj.UserSize) == 4
                if obj.UserSize(1) ~= 0 && obj.UserSize(2) ~= 0 && obj.UserSize(3) ~= 0 && obj.UserSize(4) ~= 0
                    im=double(im(obj.UserSize(1):obj.UserSize(2),obj.UserSize(3):obj.UserSize(4)));
                end
            end
            
            if obj.invertedim == 1
                im = 255-im;
            end
            
            h = ones(3)/9;
            im = conv2(im/255, h, 'same')*255;
            
            obj.imFull = im;
            obj.CamSize = size(im);
            
            fft_im = fftshift(fft2(obj.imFull));
            m = abs(fft_im);
            m(m>1000000)=1000000;
            obj.imFull_fft = (m-min(m(:)))/(max(m(:))-min(m(:)))*255;
                
        end
        function distributions(obj) %Obtaining the distribution for classifying
            
            PosData = [];
            if obj.checkHamData() == 1
                for i = 1 : length(obj.HamData)
                    PosData = [PosData; obj.HamData(i).Par(:,3:4)];
                end
                obj.datatur = 1;
                switch obj.turpar
                    case 0
                        warning('Classification Parameter is Zero')
                    case 1
                        max_tA = max(PosData(:,1));
                        [obj.nelements,obj.centers] = hist(PosData(:,1),0:max_tA*1.20);
                        obj.fit_l = 0;
                    case 2
                        max_tI = max(PosData(:,2));
                        [obj.nelements,obj.centers] = hist(PosData(:,2),0:max_tI*1.20);
                        obj.fit_l = 0;
                end                
            end
            
            
        end
        function FitLimits(obj) %Fitting for the distribution
            s = 4;  
            obj.fit_l = 0;
            switch obj.tursay
                case 1
                    try
                    f = fit(obj.centers', obj.nelements','gauss1');
                    obj.limits(1,:) = [f.b1-s*f.c1, f.b1+s*f.c1];
                    obj.fitpar = [f.a1, f.b1, f.c1];
                    obj.fitt = [(0 : max(obj.centers))', f((0 : max(obj.centers))')];
                    obj.fit_l = 1;
                    catch
                       warning('WARNING!! >> Fitting Problem') 
                    end
                case 2
                    try
                    f = fit(obj.centers', obj.nelements','gauss2');
                    obj.limits(1:2,:) = [f.b1-s*f.c1, f.b1+s*f.c1; f.b2-s*f.c2, f.b2+s*f.c2];
                    obj.fitpar = [f.a1, f.b1, f.c1; f.a2, f.b2, f.c2];
                    obj.fitt = [(0 : max(obj.centers))', f((0 : max(obj.centers))')];
                    obj.fit_l = 1;
                    catch
                       warning('WARNING!! >> Fitting Problem') 
                    end
                case 3
                    try
                    f = fit(obj.centers', obj.nelements','gauss3');
                    obj.limits = [f.b1-s*f.c1, f.b1+s*f.c1; f.b2-s*f.c2, f.b2+s*f.c2; f.b3-s*f.c3, f.b3+s*f.c3];
                    obj.fitpar = [f.a1, f.b1, f.c1; f.a2, f.b2, f.c2; f.a3, f.b3, f.c3];
                    obj.fitt = [(0 : max(obj.centers))', f((0 : max(obj.centers))')];
                    obj.fit_l = 1;
                    catch
                       warning('WARNING!! >> Fitting Problem') 
                    end
            end

        end
        function show_limits(obj) %showing limits values for command line
            ss = size(obj.fitt);
            if ss(2) ==  2
                plot(obj.fitt(:,1), obj.fitt(:,2),'-r')
                hold on
            end
            plot(obj.centers, obj.nelements,'*b')
            title('Distributions and Limits')
            hold on
            for i = 1 : obj.tursay
                plot(obj.limits(i,1)*ones(1,length(0:obj.fitpar(i,1))),0:obj.fitpar(i,1),'-','color',obj.coll(i,:))
                plot(obj.limits(i,2)*ones(1,length(0:obj.fitpar(i,1))),0:obj.fitpar(i,1),'-','color',obj.coll(i,:))
                text(obj.limits(i,1),obj.fitpar(i,1)/2,num2str(obj.limits(i,1)),'color',obj.coll(i,:))
                text(obj.limits(i,2),obj.fitpar(i,1)/2,num2str(obj.limits(i,2)),'color',obj.coll(i,:))                
            end
            hold off
        end
        function recalculation(obj) %Prepare for recalculation
            obj.classdata = [];
            obj.ClassDataMic = [];
            obj.HamData = [];
            obj.ParSay = [];
        end
        function CalcRecPar(obj) %Calcultion for RecPar parameter
            if obj.checkClassData()
                obj.RecPar = zeros(obj.tursay,1);
                
                for k = 1 : obj.tursay
                    data = 0;
                    for k2 = 1 : numel(obj.classdata(k).Par)
                        y = obj.classdata(k).Par(k2).Data(:,4);
                        data = [data; y];
                    end
                    data = data(~isnan(data));
                    obj.RecPar(k) = round(2*mean(sqrt(data)));
                    if obj.RecPar(k) < 20
                        obj.RecPar(k) = 20;
                    end
%                     disp(data);

                end
            else
                obj.RecPar = [20, 20, 20];
            end
        end
        function gR = CalcGR(obj, data) %Calculation for gr function
            coords = data';
            Lx = obj.CamSize(2);
            Ly = obj.CamSize(1);
            L = sqrt(Lx^2+Ly^2);
            nPart = size(coords,2);
            NumOfBins=100;
            
            gR = struct;
            
                gR.count = 0;
                gR.range = [0 0.3*L];
                gR.increment = 0.3*L/NumOfBins;
                gR.outFreq = 1000;

                
            for partA = 1:(nPart-1)
                for partB = (partA+1):nPart
                             
                    vec = coords(:,partA) - coords(:,partB); 
                    hLx = Lx/2.0;
                    hLy = Ly/2.0;

                    if vec(1) > hLx
                        vec(1) = vec(1) - Lx;
                    elseif vec(1) < -hLx
                        vec(1) = vec(1) + Lx;
                    end

                    if vec(2) > hLy
                        vec(2) = vec(2) - Ly;
                    elseif vec(2) < -hLy
                        vec(2) = vec(2) + Ly;
                    end
                    r = sqrt(sum(dot(vec,vec)));

 
                    if (r < 0.3*L)
                        gR = obj.addPoint(gR,r);
                    end
                end
            end
            
                nBins = size(gR.values,2);
                nPart = size(coords,2);
                rho = nPart/(Lx*Ly); 
                
                for bin = 1:nBins
                    rVal = gR.values(bin);
                    next_rVal = gR.increment + rVal;
                    ereaBin = pi*next_rVal^2 - pi*rVal^2; 
                    nIdeal = ereaBin*rho;
                    gR.histo(bin) = gR.histo(bin) / nIdeal;
                end

                gR.histo = 2*gR.histo/(nPart-1);
                
        end
        function h = addPoint(obj, h, data) %Subfunction for gr calculation



            if (h.count == 0)
                nBins = ceil((h.range(2)-h.range(1))/h.increment);

                h.range(2) = h.range(1) + nBins * h.increment;

                h.histo = zeros(1,nBins);

                h.values = 1:nBins;
                h.values = h.range(1) + h.increment*(h.values-0.5);
            end

            if (data > h.range(1) && data <= h.range(2))

                binIndex = ceil((data-h.range(1))/h.increment);

                h.histo(binIndex) = h.histo(binIndex)+1;

                h.count = h.count+1;

            else
                return
            end

        end
        function v = CalcVelocity(obj, data) %Calculation for velocities
            v = [];
            findfirst = 0;
            if ~isempty(data)
                for i = 1 : length(data)
                    x = data(i,2);
                    y = data(i,3);
                    t = data(i,1);
                    if ~isnan(x) && ~isnan(y)
                        if findfirst == 0
                            findfirst = i;
                            v = [v;[0, 0, 0, 0]];
                        else
                            vx = data(findfirst,2) - x;
                            vy = data(findfirst,3) - y;
                            tt = t - data(findfirst,1);
                            var = sqrt(vx.^2 + vy.^2);
                            va = var/tt;
                            
                            vx = data(i-1,2) - x;
                            vy = data(i-1,3) - y;
                            tt = t - data(i-1,1);
                            vmr = sqrt(vx.^2 + vy.^2);
                            vm = vmr/tt;
                            
                            v = [v;[var, vmr, va, vm]];
                            
                        end
                    else
                        v = [v;[NaN, NaN, NaN, NaN]];
                    end
                end
            end
        end
        function PlotTrajectory(obj,k,k2, index) %Plotting trajectory for single particle

            xx = obj.classdata(k).Par(k2).Data(1:index,2);
            yy = obj.classdata(k).Par(k2).Data(1:index,3);
            
            x = [];
            y = [];
            r = [];
            n = 0;
            for i = 1 : length(xx)
                if ~isnan(xx(i)) && ~isnan(yy(i))
                    n = n + 1;
                    x = [x; xx(i)];
                    y = [y; yy(i)];
                    r = [r; sqrt(xx(i).^2 + yy(i).^2)];
                end
            end
            
            ff = figure;
            axx = axes(ff);            
            
            
            plot(axx, x, y, 'k');
            hold on
            quiver(x(1),y(1),x(end)-x(1),y(end)-y(1),1,'r','LineWidth', 1.5)
            plot(axx,x(1),y(1),'ob','MarkerSize', 10)
            plot(axx,x(end),y(end),'og','MarkerSize', 10)
            axis(axx,'equal', 'ij');
            
            set(axx,...
                'Units'       ,'Normalized',...
                'Box'         , 'on'      , ...
                'TickDir'     , 'in'      , ...
                'TickLength'  , [.02 .02] , ...
                'XMinorTick'  , 'on'      , ...
                'YMinorTick'  , 'on'      , ...
                'XGrid'       , 'on'      , ...
                'YGrid'       , 'on'      , ...
                'XColor'      , [.0 .0 .0], ...
                'YColor'      , [.0 .0 .0], ...
                'LineWidth'   , 1         , ...
                'FontUnits'   ,'points'   , ...
                'FontWeight'  ,'normal'   , ...
                'FontName'    ,'Times'    , ...
                'FontSize'    ,12         , ...
                'LineWidth'   ,0.5        );
            
            tt = [ num2str(k) 'th. kind '  num2str(k2) 'th. Particle'];
            title(tt,...
                'FontUnits','points',...
                'FontWeight','normal',...
                'FontSize',12,...
                'FontName','Times')

            ylabel({'Y Direction (pixels)'},...
                    'FontUnits','points',...
                    'FontWeight','normal',...
                    'FontSize',12,...
                    'FontName','Times')
            xlabel('X Direction (pixels)',...
                    'FontUnits','points',...
                    'FontWeight','normal',...
                    'FontSize',12,...
                    'FontName','Times')
                
        end
        function PlotMSD(obj,k,k2) %Ploting MSD calculation

            xx = obj.classdata(k).Par(k2).Data(1:end,2);
            yy = obj.classdata(k).Par(k2).Data(1:end,3);
            
            xx = xx*obj.pix2mic;
            yy = yy*obj.pix2mic;

            x = [];
            y = [];
            r = [];
            n = 0;
            for i = 1 : length(xx)
                if ~isnan(xx(i)) && ~isnan(yy(i))
                    n = n + 1;
                    x = [x; xx(i)];
                    y = [y; yy(i)];
                    r = [r; sqrt(xx(i).^2 + yy(i).^2)];
                end
            end
            

            t_meas = n/obj.FrameRate ;
            dt = t_meas / ( n - 1 );

            for i = 1:n/2
                MSDx(i) = mean((x(i+1:1:end)-x(1:1:end-i)).^2);
                MSDy(i) = mean((y(i+1:1:end)-y(1:1:end-i)).^2);
                MSDr(i) = mean((r(i+1:1:end)-r(1:1:end-i)).^2);
                Zn(i) = i*dt;
            end
            
            
            
            
            
            
            
            
            
            
            

           ff = figure;
           axx = axes(ff);
           
%             loglog(Zn,MSDx,'-r','LineWidth'   ,0.5)
%             hold on
%             loglog(Zn,MSDy,'-b','LineWidth'   ,0.5)
            loglog(Zn,MSDr,'-k','LineWidth'   ,1.5)

            set(axx,...
                'Units'       ,'Normalized',...
                'Box'         , 'on'      , ...
                'TickDir'     , 'in'      , ...
                'TickLength'  , [.02 .02] , ...
                'XMinorTick'  , 'on'      , ...
                'YMinorTick'  , 'on'      , ...
                'XGrid'       , 'on'      , ...
                'YGrid'       , 'off'      , ...
                'XColor'      , [.0 .0 .0], ...
                'YColor'      , [.0 .0 .0], ...
                'LineWidth'   , 1         , ...
                'FontUnits'   ,'points'   , ...
                'FontWeight'  ,'normal'   , ...
                'FontName'    ,'Times'    , ...
                'FontSize'    ,12         , ...
                'LineWidth'   ,0.5        );
            
            tt = [ num2str(k) 'th. kind '  num2str(k2) 'th. Particle'];
            title(tt,...
                'FontUnits','points',...
                'FontWeight','normal',...
                'FontSize',12,...
                'FontName','Times')

            ylabel({'MSD (\mum^2)'},...
                    'FontUnits','points',...
                    'FontWeight','normal',...
                    'FontSize',12,...
                    'FontName','Times')
            xlabel('Time (ms)',...
                    'FontUnits','points',...
                    'FontWeight','normal',...
                    'FontSize',12,...
                    'FontName','Times')


            legend({'Displacement'},...%'FontUnits','points',...
                'FontWeight','normal',...
                'FontSize',12,...
                'FontName','Times',...
                'Location','NorthWest')
            
        end
    end
end
