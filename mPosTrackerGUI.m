% This code is written by Harun, 2021
classdef mPosTrackerGUI < handle
    properties
        Tracker
    end    
    properties (Access = private) % GUI Veriables
        ProgName = 'mPosTracker';
        MainWinPos
        WinBackgroundColor = [1 1 1];
        PanelBackgroundColor = [1 1 1];
        statusFontSize = 12;
        FontSize = 8;
        BarHeight = 50;
        StatusBarHeight = 25;
        SidePanelWidth = 250;
        icons
        scrol_index
        sld1size = 25;
        inArea = [];
    end
    properties (Access = private)%GUI Objects
        h, logo, p0, p1, p2, p3, p4
        
        ax, im, pl, sld1
        rec, RecPar = 20
        rec_inArea, pat
        c_menu, SelectedObj, pl_t
        v_menu, v_check
        n_menu, n_seepar, n_seeall, n_seeinArea
        fft_menu
        
        statusMsg, sideform
        
        zoomIn_btn, zoomOut_btn, pan_btn, analysis_btn
        video_btn, posfinder_btn, classify_btn, fft_btn
        inArea_btn, PlotNumPar_btn, PlotVCell_btn, PlotPairCol_btn
        
    end
    properties (Access = private)%Menus
        m_project
            m_newp
            m_openp
            m_savep
            m_closep
            m_exit

        m_last
            m_help
            m_about
    end
    methods % Constructor
        function app = mPosTrackerGUI()
            
            app.generateForm();
            app.createMenus();
            app.loadimages();
            app.init();
        end
    end
    methods (Access = private)% Generate Win Form and callbacks
        function generateForm(app)
            app.h = figure('Units','Normalized'...
                ,'Position',[0.2 0.2 0.6 0.6]...
                ,'toolbar', 'none'...
                ,'name', app.ProgName...
                ,'menubar', 'none'...
                ,'WindowStyle','normal'...
                ,'NumberTitle','off'...
                ,'visible','on'...
                ,'CloseRequestFcn', @app.closeWin...
                ,'Color', app.WinBackgroundColor);

            app.MainWinPos = app.takepos(app.h);
            
            app.p0 = uipanel(app.h, 'Units','pixels','Position', [0.0 0.0 app.MainWinPos(3) app.MainWinPos(4)], 'BackgroundColor', app.PanelBackgroundColor, 'BorderType', 'none');
            app.logo = uicontrol(app.p0,'style','checkbox', 'BackgroundColor', [1 1 1],...
                     'Units','normalized', 'Position', [0.0 0.0 1.0 1.0], 'enable','inactive', 'visible', 'on');
                 
            app.p1 = uipanel(app.h, 'Units','pixels','Position', [0.0 app.MainWinPos(4)-app.BarHeight app.MainWinPos(3) app.BarHeight], 'BackgroundColor', app.PanelBackgroundColor);
            app.p2 = uipanel(app.h, 'Units','pixels','Position', [0.0 app.StatusBarHeight app.MainWinPos(3)- app.SidePanelWidth app.MainWinPos(4)-(app.BarHeight+app.StatusBarHeight)], 'BackgroundColor', app.PanelBackgroundColor);
            app.p3 = uipanel(app.h, 'Units','pixels','Position', [app.MainWinPos(3) - app.SidePanelWidth app.StatusBarHeight app.MainWinPos(3) app.MainWinPos(4)- (app.BarHeight+app.StatusBarHeight) ], 'BackgroundColor', app.PanelBackgroundColor);
            app.p4 = uipanel(app.h, 'Units','pixels','Position', [0.0 0.0 app.MainWinPos(3) app.StatusBarHeight], 'BackgroundColor', app.PanelBackgroundColor);

            
            app.ax = axes('parent', app.p2, 'Position', [0.065 0.125 0.875 0.825]);
            app.im = image(app.ax);
            set(app.ax, 'nextplot', 'add');
            app.pl = plot(app.ax,0,0);
            app.pl_t = plot(app.ax,0,0);
            app.rec = rectangle(app.ax);
            app.rec_inArea = rectangle(app.ax);
            app.pat = patch(app.ax);
            
            app.c_menu = uicontextmenu(app.h);
                uimenu(app.c_menu, 'Label', 'see Trajectory', 'callback', @app.cmenu1);
                uimenu(app.c_menu, 'Label', 'plot Trajectory', 'callback', @app.cmenu3);
                uimenu(app.c_menu, 'Label', 'see Time Series as a Table', 'callback', @app.cmenu2);
                uimenu(app.c_menu, 'Label', 'Calculate MSD', 'callback', @app.cmenu4);
%                 uimenu(app.c_menu, 'Label', 'Calculate MSD', 'callback', @app.cmenu4);
                
            app.v_menu = uicontextmenu(app.h);
                app.v_check = uimenu(app.v_menu, 'Label', 'Calc. Six Fold Parameters', 'callback', @app.sixfold);
                uimenu(app.v_menu, 'Label', 'Exract Voronoi Cells', 'callback', @app.exractvoronoicells);
                uimenu(app.v_menu, 'Label', 'Exract Image', 'callback', @app.exractimage);
                
            app.n_menu = uicontextmenu(app.h);
                app.n_seepar = uimenu(app.n_menu, 'Label', 'see Particles', 'checked', 'on', 'callback', @app.call_n_seepar);
                app.n_seeall = uimenu(app.n_menu, 'Label', 'see All Trajectories', 'callback', @app.call_n_seeall);
                app.n_seeinArea = uimenu(app.n_menu, 'Label', 'see The Interesting Area', 'callback', @app.call_n_seeinArea);
                uimenu(app.n_menu, 'Label', 'Exract Image', 'callback', @app.exractimage);
                uimenu(app.n_menu, 'Label', 'Exract Positions', 'callback', @app.exractpositions);
                
            app.fft_menu = uicontextmenu(app.h);
                uimenu(app.fft_menu, 'Label', 'Exract Image', 'callback', @app.exractimage);
            
            set(app.ax, 'nextplot', 'replace');
                
            app.sld1 = uicontrol(app.p2,'style','slider','callback', @app.call_sld1, 'BackgroundColor', app.WinBackgroundColor,...
            'Units','normalized', 'Position', [0.065 0.005 0.875 0.065], 'enable','off');
        
            app.statusMsg = uicontrol(app.p4,'style','text','string', 'mPosTracker','fontsize',app.statusFontSize,...
                'HorizontalAlignment','left','Units','normalized', 'Position', [0 0 1 1], 'BackgroundColor', app.WinBackgroundColor);
%             for i = 1 : 7
%                 app.sideform(i) = uicontrol(app.p3, 'style','text' , 'String', 'Projet Information'...
%                     ,'HorizontalAlignment', 'left', 'Units','pixels', 'Position', [0 0 100 20],'BackgroundColor', [1 1 1]);
%             end
            app.sideform = uitable(app.p3, 'units', 'normalized', 'position', [0 0 1 1],...
            'ColumnName',{'Properties'; 'Values'}, 'RowName',{});
        


            set(app.h, 'SizeChangedFcn', @app.resize);
        end
        function createMenus(app)
            app.m_project = uimenu(app.h,'Text','Project');
                app.m_newp= uimenu(app.m_project,'Text','New Project','MenuSelectedFcn',@app.call_m_newp);
                app.m_openp= uimenu(app.m_project,'Text','Open Project','MenuSelectedFcn',@app.call_m_openp);
                app.m_savep= uimenu(app.m_project,'Text','Save Project','MenuSelectedFcn',@app.call_m_savep);
                app.m_closep= uimenu(app.m_project,'Text','Close Project','MenuSelectedFcn',@app.call_m_closep);
                app.m_exit= uimenu(app.m_project,'Text','Exit','separator', 'on','MenuSelectedFcn',@app.call_m_exit);
                
%             app.m_video = uimenu(app.h,'Text','Video');
%                 app.m_Vproperties = uimenu(app.m_video,'Text','Video Properties','MenuSelectedFcn',@app.call_m_Vpropertiesp);
%                 app.m_video_btn  = uimenu(app.m_video,'Text','set Video Properties','MenuSelectedFcn',@app.call_m_video_btn);
%             app.m_posfinder = uimenu(app.h,'Text','PosFinder');
%             
%             app.m_classify = uimenu(app.h,'Text','Track and Classify');
            
            app.m_last = uimenu(app.h,'Text','About');
                %app.m_help = uimenu(app.m_last,'Text','Help','MenuSelectedFcn',{@app.call_help});
                app.m_about = uimenu(app.m_last,'Text','About','separator', 'off', 'MenuSelectedFcn',{@app.call_about});
                
                
            app.zoomIn_btn = uicontrol(app.p1,'style', 'togglebutton', 'Callback', @app.call_zoomIn, 'String', '', 'TooltipString', 'Zoom In',...
                'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
            app.zoomOut_btn = uicontrol(app.p1,'style', 'togglebutton','Callback', @app.call_zoomOut, 'String', '', 'TooltipString', 'Zoom Out',...
                'Units','pixels',  'enable','on', 'BackgroundColor', [1 1 1]);
            app.pan_btn = uicontrol(app.p1,'style', 'togglebutton','Callback', @app.call_pan, 'String', '', 'TooltipString', 'Pan',...
                'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]); 
%             app.info_btn = uicontrol(app.p1,'style', 'pushbutton','Callback', @app.call_info, 'String', '', 'TooltipString', 'Project Info',...
%                 'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]); 
            app.video_btn = uicontrol(app.p1,'Callback', @app.call_video, 'String', '', 'TooltipString', 'Video Properties',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
            app.posfinder_btn = uicontrol(app.p1,'Callback', @app.call_posfinder, 'String', '', 'TooltipString', 'PosFinder Properties',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
            app.classify_btn = uicontrol(app.p1,'Callback', @app.call_classify, 'String', '', 'TooltipString', 'Tracking and Classification',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
        
            app.fft_btn = uicontrol(app.p1,'style', 'togglebutton', 'Callback', @app.call_fft, 'String', '', 'TooltipString', 'see FFT of images',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
        
            app.inArea_btn = uicontrol(app.p1,'Callback', @app.call_inArea, 'String', '', 'TooltipString', 'Determine Interesting Area',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
            app.PlotNumPar_btn = uicontrol(app.p1,'Callback', @app.call_PlotNumPar, 'String', '', 'TooltipString', 'Plot Number of Particles',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
            app.PlotPairCol_btn = uicontrol(app.p1, 'Callback', @app.call_PlotPairCol, 'String', '', 'TooltipString', 'Plot Pair Correlation Function',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
            app.PlotVCell_btn = uicontrol(app.p1, 'style', 'togglebutton', 'Callback', @app.call_PlotVCell, 'String', '', 'TooltipString', 'Plot Voronoi Cells',...
            'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
        
%             app.start_btn = uicontrol(app.p1,'Callback', @app.call_start, 'String', '', 'TooltipString', 'Start for PosFinder',...
%             'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1]);
%             app.pause_btn = uicontrol(app.p1,'Callback', @app.call_pause, 'String', '', 'TooltipString', 'Pause',...
%             'Units','pixels','enable','on', 'BackgroundColor', [1 1 1]);
%             app.stop_btn = uicontrol(app.p1,'Callback', @app.call_stop, 'String', '', 'TooltipString', 'Stop',...
%             'Units','pixels','enable','on', 'BackgroundColor', [1 1 1]); 

        end
        function closeWin(app,~,~)
            if app.Tracker.isexistvideo()
                if app.isSaved() == 0
                    c = app.qBox(1, ['The project (' app.Tracker.ProjectName ') is not saved. Do you want to save it?']);
                    if ~isnan(c) && c == 1
                        app.call_m_savep();
                    end
                    delete(app.h);
                else
                    c = app.qBox(2, 'Do you want to exit?');
                    if ~isnan(c) && c == 1
                        delete(app.h);
                    end
                end
            else
                c = app.qBox(2, 'Do you want to exit?');
                if ~isnan(c) && c == 1
                    delete(app.h);
                end
            end
        end
        function init(app)
            
            app.Tracker = mPosTracker();
            
            set(app.ax, 'visible', 'on');
            set(app.ax, 'YDir', 'reverse');
            set(app.ax, 'box', 'on');
            set(app.ax, 'DataAspectRatio', [1 1 1]);
            set(app.ax, 'PlotBoxAspectRatio', [1 1 1]);
            colormap(app.ax, gray(255));
            title(app.ax,'Image and Positions')
            set(app.im, 'CData', app.icons.logo);
            
            
            delete(app.pat);
            delete(app.rec);
            delete(app.pl);
            reset(app.pl_t);
            reset(app.rec_inArea);
            reset(app.im);
            app.SelectedObj=[];
            
            app.addMsg('Create a New Project and Load a video(*.avi)');

            app.resize();
        end
        function resize(app, ~,~)
            app.MainWinPos = app.takepos(app.h);
            set(app.p0, 'Position', [0.0 0.0 app.MainWinPos(3) app.MainWinPos(4)]);
            app.seticons(app.icons.logo, app.logo);     
            set(app.p1, 'Position', [0.0 app.MainWinPos(4)-app.BarHeight app.MainWinPos(3) app.BarHeight]);
            set(app.p2, 'Position', [0.0 app.StatusBarHeight app.MainWinPos(3)- app.SidePanelWidth app.MainWinPos(4)-(app.BarHeight+app.StatusBarHeight)]);
            set(app.p3, 'Position', [app.MainWinPos(3) - app.SidePanelWidth app.StatusBarHeight app.SidePanelWidth app.MainWinPos(4)- (app.BarHeight+app.StatusBarHeight) ]);
            set(app.p4, 'Position', [0.0 0.0 app.MainWinPos(3) app.StatusBarHeight]);
            
            pos = app.takepos(app.p2);
            set(app.ax, 'unit', 'pixels');
            set(app.ax, 'position', [pos(3)*0.1 70 pos(3)*0.8 (pos(4)-70)*0.925]);  

            set(app.sld1, 'unit', 'pixels');
            set(app.sld1, 'position', [pos(3)*0.15 10 pos(3)*0.7 25]);
            
            pos = app.takepos(app.p3);
            set(app.sideform, 'units', 'pixels',...
                'position', [0 0 pos(3) pos(4)], 'ColumnWidth',{pos(3)/2-5 pos(3)/2-5});
            
            
            a = app.BarHeight*0.9;
            b = app.BarHeight*0.05;
        
            objs = [app.zoomIn_btn, app.zoomOut_btn, app.pan_btn,...
                    app.video_btn, app.posfinder_btn,...
                    app.classify_btn, ...
                    app.inArea_btn, app.PlotNumPar_btn, app.PlotVCell_btn, app.fft_btn,app.PlotPairCol_btn];
            ts = 0;
            for i = 1 : length(objs)
                if i == 4 || i==7
                    ts = ts + 30;
                end
                set(objs(i),'position', [floor(i*b+(i-1)*a + ts) floor(b/2) floor(a) floor(a)])
            end
            
            
            app.seticons(app.icons.zoomin, app.zoomIn_btn);
            app.seticons(app.icons.zoomout, app.zoomOut_btn);
            app.seticons(app.icons.pan, app.pan_btn);
%             app.seticons(app.icons.info, app.info_btn);
            app.seticons(app.icons.video, app.video_btn);
            app.seticons(app.icons.posfinder, app.posfinder_btn);
%             app.seticons(app.icons.start, app.start_btn);
%             app.seticons(app.icons.pause, app.pause_btn);
%             app.seticons(app.icons.stop, app.stop_btn);
            app.seticons(app.icons.classify, app.classify_btn);
            
            app.seticons(app.icons.fft, app.fft_btn);
            app.seticons(app.icons.inArea, app.inArea_btn);
            app.seticons(app.icons.PlotNumPar, app.PlotNumPar_btn);
            app.seticons(app.icons.PlotVCell, app.PlotVCell_btn);
            app.seticons(app.icons.PlotPairCol, app.PlotPairCol_btn);

            app.renewform();

        end
        function call_m_newp(app, ~,~)
            if app.Tracker.isexistvideo()
                if app.isSaved() == 0
                    c = app.qBox(2, ['Project' app.Tracker.ProjectName ' is not saved. Do you want to save it?']);
                    if ~isnan(c) && c == 1
                        app.call_m_savep();
                    end
                end
            end
            [filename, pathname] = uigetfile('*.avi','Select AVI file');
            if filename ~= 0
                
                app.init();
                
                if filename(length(filename)-3) == '.'
                    app.Tracker.ProjectName = filename(1:length(filename)-4);
                else
                    app.Tracker.ProjectName = filename;
                end
                
                app.Tracker.addVideo(pathname, filename)
                app.scrol_index = app.Tracker.current_index;
                app.setsld1;
                app.Tracker.save_project_l = 0;
                app.addMsg([filename ' is loaded!']);
                app.inArea = [];
                app.renewform();
            end            
        end
        function call_m_openp(app, ~,~)
            if app.isSaved() == 0 && app.Tracker.isexistvideo()
                c = app.qBox(2, ['Project' app.Tracker.ProjectName ' is not saved. Do you want to save it?']);
                if ~isnan(c) && c == 1
                    app.call_m_savep();
                end
            end
            [filename, pathname] = uigetfile('*.mPos','Select mPos file');
            if pathname ~= 0
%                 if filename(length(filename)-4) == '.'
%                     app.Tracker.ProjectName = filename(1:length(filename)-5);
%                 else
%                     app.Tracker.ProjectName = filename;
%                 end
                tempTracer = mPosTracker();
                tempTracer.readProject(pathname, filename);
                cik = 0;
                while cik == 0
                    if ~tempTracer.isexistvideo()
                        c = app.qBox(1, ['Video File (' tempTracer.vid_filename ') is not Exist. Can you find it?']);
                        if c == 1
                            [v_filename, v_pathname] = uigetfile('*.avi','Select AVI file');
                            if v_pathname ~= 0
                            if exist([v_pathname v_filename], 'file') > 0
                                tempTracer.video = VideoReader([v_pathname v_filename]);
                                tempTracer.vid_filename = v_filename;
                                tempTracer.vid_pathname = v_pathname;
                                tempTracer.video_l = 1;
                                tempTracer.save_project_l = 0;
                                cik = 1;
                            else
                                tempTracer.video_l = 0;
                                cik = 0;
                            end
                            end
                        else
                            cik = 2;
                        end
                    else
                        cik = 1;
                        tempTracer.save_project_l = 1;
                    end
                end
                if cik == 1
                    app.init();
                    tempTracer.save_project_file = filename;
                    tempTracer.save_project_path = pathname;
                    app.Tracker = tempTracer;
                    app.scrol_index = app.Tracker.current_index;
                    app.setsld1;
                    set(app.sld1, 'value', app.scrol_index);
                    app.addMsg(['The Project (' app.Tracker.ProjectName ') is loaded!']);
                    app.inArea = [];
                    app.renewform(); 
                else
                    app.renewform(); 
                end
            end
        end
        function call_m_savep(app, ~,~)
            if exist([app.Tracker.save_project_path app.Tracker.save_project_file], 'file') > 0
                app.Tracker.saveProject(app.Tracker.save_project_path, app.Tracker.save_project_file);
                app.Tracker.save_project_l = 1;
                app.addMsg(['The Project (' app.Tracker.ProjectName ') is saved!']);
            else
                file = [app.Tracker.ProjectName '.mPos'];
                [file, path] = uiputfile('*.mPos','Save the project as *.mPos file',file);
                if path ~= 0 %&& file ~= 0
                    app.Tracker.save_project_file = file;
                    app.Tracker.save_project_path = path;
                    app.Tracker.saveProject(path, file);
                    app.Tracker.save_project_l = 1;
                    app.addMsg(['The Project (' app.Tracker.ProjectName ') is saved!']);
                else
                end
            end
            app.renewform;
        end
        function call_m_closep(app, ~,~)
            if app.isSaved() == 0
                c = app.qBox(2, ['Project' app.Tracker.ProjectName ' is not saved. Do you want to save it?']);
                if ~isnan(c) && c == 1
                    app.call_m_savep();
                end
            end
            app.init();
            app.addMsg('The Project is closed!');
            app.renewform();
        end
        function call_m_exit(app, ~,~)
            app.closeWin();
        end
        function call_help(app, ~,~)
            %app.helpGUI();
        end
        function call_about(app, ~,~)
            app.aboutGUI();
        end
        function call_sld1(app, ~,~)
            aa = round( get(app.sld1,'Value'));
            app.scrol_index = aa;
            app.renewform();
        end
        function call_zoomIn(app, ~, ~)
            set(app.zoomOut_btn, 'value', 0);
            set(app.pan_btn, 'value', 0);
            zoom(app.h,'off');
            pan(app.h,'off');
            aa = get(app.zoomIn_btn,'value');
            if aa == 1
                zoom(app.h,'inmode');
                get(app.zoomIn_btn,'value');
            else
                zoom(app.h,'off');
            end
        end
        function call_zoomOut(app, ~, ~)
            set(app.zoomIn_btn, 'value', 0);
            set(app.pan_btn, 'value', 0);
            zoom(app.h,'off');
            pan(app.h,'off');
            aa = get(app.zoomOut_btn,'value');
            if aa == 1
                zoom(app.h,'outmode');
            else
                zoom(app.h,'off')
            end
        end
        function call_pan(app, ~, ~)
            set(app.zoomIn_btn, 'value', 0);
            set(app.zoomOut_btn, 'value', 0);
            zoom(app.h,'off');
            aa = get(app.pan_btn,'value');
            if aa == 1
                pan(app.h,'onkeepstyle');
            else
                pan(app.h,'off')
            end 
        end
        function call_video(app, ~, ~)
            app.zoomButtonReset();
            app.set_ROI();
            app.Tracker.Prepare();
            app.setsld1();
            set(app.sld1, 'value', app.scrol_index);
            app.renewform();
        end
        function call_posfinder(app, ~, ~)
            app.zoomButtonReset();
            app.posfinder();
            set(app.sld1, 'value', app.scrol_index);
            app.renewform();
        end
        function call_classify(app, ~, ~)
            app.classyf();
            if app.Tracker.checkClassData()
                app.createobjs();
            end
            app.renewform();
            
        end
        function call_fft(app, ~, ~)
            app.renewform();
        end  
        function call_inArea (app, ~, ~)
            app.det_inArea();
            app.renewform();
        end
        function call_PlotNumPar (app, ~, ~)
                if app.Tracker.checkHamData() && app.Tracker.checkClassData()
                    objs = findobj(app.h, 'enable', 'on');
                    set(objs, 'enable', 'off');
                    set(app.h, 'pointer', 'watch');
                    pause(0.2);
                    data = [0, 0, 0, 0, 0];
                    if ~isempty(app.inArea)
                        figure;
                        str_legend = {};
                        cc = {'1st. Kind (Red)', '2nd. Kind (Green)', '3rd. Kind (Blue)'};
                        for index = 1 : length(app.Tracker.TimeSer)
                            n = [0, 0, 0];
                            for k = 1 : app.Tracker.tursay
                                for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                                    x = app.Tracker.classdata(k).Par(k2).Data(index,2);
                                    y = app.Tracker.classdata(k).Par(k2).Data(index,3);
                                    if ~isnan(x) && ~isnan(y)
                                        if x >= app.inArea(1) && x <= app.inArea(1) + app.inArea(3) - 1
                                            if y >= app.inArea(2)&& y <= app.inArea(2) + app.inArea(4) - 1
                                                n(k) = n(k) + 1; 
                                            end
                                        end
                                    end
                                end
                            end
                            data = [data; app.Tracker.TimeSer(index), n(1), n(2), n(3), n(1) + n(2) + n(3)];
                        end
                        for k = 1 : app.Tracker.tursay
                            plot(data(:,1), data(:,k + 1), 'color', app.Tracker.coll(k,:));
                            str_legend = [str_legend, cc{k}];
                            hold on
                        end
                        plot(data(:,1), data(:,5), 'color', 'k');
                        str_legend = [str_legend, {'Total'}];
                        hold off
                        xlabel('Time')
                        ylabel('Number of Particles')
                        legend(str_legend,...%'FontUnits','points',...
                            'FontWeight','normal',...
                            'FontSize',12,...
                            'FontName','Times',...
                            'Location','NorthWest')
                    else
                        
                    end
                    set(app.h, 'pointer', 'arrow');
                    set(objs, 'enable', 'on');
                end
        end
        function call_PlotVCell (app, e, ~)
            app.renewform();
%             a = get(e, 'value');
        end
        function call_PlotPairCol (app, ~, ~)
            if app.Tracker.checkClassData() && app.Tracker.partnum(app.scrol_index) > 2
                data = [];
                for k = 1 : app.Tracker.tursay
                    for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                        x = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,2);
                        y = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,3);
                        if ~isnan(x) && ~isnan(y)
                            data = [data; x, y];
                        end
                    end
                end
                if ~isempty(data)
                    gR = app.Tracker.CalcGR(data);

                    figure, plot(gR.values,gR.histo, '-b');
                    xlabel('distance');
                    ylabel('g(r)');
                else
                    c = app.qBox(3, 'There is no data');
                end
            end
        end
        function sixfold(app, e, ~)
            a = get(e, 'checked');
%             app.logic(a)
            if app.logic(a) == 0
                set(e, 'checked', 'on');
            else
                set(e, 'checked', 'off');
            end
            app.renewform();
        end
        function call_n_seepar(app, e, ~)
            a = get(e, 'checked');
%             app.logic(a)
            if app.logic(a) == 0
                set(app.n_seepar, 'checked', 'on');
                set(app.n_seeall, 'checked', 'off');
            else
                set(app.n_seepar, 'checked', 'off');
                set(app.n_seeall, 'checked', 'on');
            end
            app.renewform();
        end
        function call_n_seeall(app, e, ~)
            a = get(e, 'checked');
%             app.logic(a)
            if app.logic(a) == 0
                set(app.n_seepar, 'checked', 'off');
                set(app.n_seeall, 'checked', 'on');
            else
                set(app.n_seepar, 'checked', 'on');
                set(app.n_seeall, 'checked', 'off');
            end
            app.renewform();
        end
        function call_n_seeinArea(app, e, ~)
            a = get(e, 'checked');
%             app.logic(a)
            if app.logic(a) == 0
                set(e, 'checked', 'on');
            else
                set(e, 'checked', 'off');
            end
            app.renewform();
        end
        function exractvoronoicells(app, ~, ~)
            if ~isempty(app.inArea) && app.Tracker.partnum(app.scrol_index) > 2
                vdata = [];
                for k = 1 : app.Tracker.tursay
                    for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                        x = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,2);
                        y = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,3);
                        if ~isnan(x) && ~isnan(y) && ~isinf(x) && ~isinf(y)
                            vdata = [vdata; x, y];
                        end
                    end
                end
                [V,C] = voronoin([vdata(:,1), vdata(:,2)]);
                VoronoiCells = {V, C};
                
                if app.Tracker.vid_filename(length(app.Tracker.vid_filename)-3) == '.'
                    file = app.Tracker.vid_filename(1:length(app.Tracker.vid_filename)-4);
                else
                    file = app.Tracker.vid_filename;
                end
                file = [file '_avi_Voronoi_' num2str(app.scrol_index) '.mat'];
                [file, path, FilterIndex] = uiputfile({'*.mat'},'Save Voronoi Cells',file);

                if path ~= 0 %&& file ~= 0
                    switch FilterIndex
                        case 1
                            save([path file], 'VoronoiCells','-mat');
                    end
                else
                end
            end
        end
        function exractimage(app, ~, ~)
            frame = getframe(app.ax);
            imm = frame2im(frame);
            if app.Tracker.vid_filename(length(app.Tracker.vid_filename)-3) == '.'
                file = app.Tracker.vid_filename(1:length(app.Tracker.vid_filename)-4);
            else
                file = app.Tracker.vid_filename;
            end
            file = [file '_avi_' num2str(app.scrol_index) '.png'];
            [file, path, FilterIndex] = uiputfile({'*.png'; '*.jpg'; '*.bmp'},'Save Images',file);

            if path ~= 0 %&& file ~= 0
                switch FilterIndex
                    case 1
                        imwrite(imm,[path file],'png');
                    case 2
                        imwrite(imm,[path file],'jpg');
                    case 3
                        imwrite(imm,[path file],'bmp');
                    case 4
%                         print(app.h,[path file],'-deps2');
                end
            else
            end
        end
        function exractpositions(app, ~, ~)
            if app.Tracker.checkHamData()
                if app.Tracker.checkClassData()
                    data = [];
                    for k = 1 : app.Tracker.tursay
                        for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                            x = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,2);
                            y = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,3);
                            if ~isnan(x) && ~isnan(y) && ~isinf(x) && ~isinf(y)
                                data = [data; x, y, k, k2];
                            end
                        end
                    end
                    if app.Tracker.vid_filename(length(app.Tracker.vid_filename)-3) == '.'
                        file = app.Tracker.vid_filename(1:length(app.Tracker.vid_filename)-4);
                    else
                        file = app.Tracker.vid_filename;
                    end
                    file = [file '_avi_Points_' num2str(app.scrol_index) '.xls'];
                    [file, path, FilterIndex] = uiputfile({'*.xls'; '*.txt'; '*.mat'},'Save Data as a .xls file',file);

                    if path ~= 0 %&& file ~= 0
                        switch FilterIndex
                            case 1
                                xlswrite([path file], data);
                            case 2
                                fid=fopen([path file],'w');
                                fprintf(fid, 'X(pixel) Y(pixel) Kind Particle\r\n');
                                fprintf(fid, '%5.3f %5.3f %5.3f %5.3f \r\n', data');
                                fclose(fid);
                            case 3
                                save([path file], 'data','-mat');
                        end
                    else
                    end
                end
            end

        end
        function pointselected(app, obj, e)
            if ~isempty(app.SelectedObj)
                pos = get(app.SelectedObj, 'userdata');
                pos2 = get(obj, 'userdata');
                if pos(1)~=pos2(1) || pos(2)~=pos2(2)
                    switch pos(1)
                        case 1
                            set(app.SelectedObj, 'edgecolor', 'r');
                        case 2
                            set(app.SelectedObj, 'edgecolor', 'g');
                        case 3
                            set(app.SelectedObj, 'edgecolor', 'b');
                    end
                    if e.Button == 1
                        reset(app.pl_t);
                    end
                end
            end
            set(obj, 'edgecolor','y');
            app.SelectedObj = obj;
        end
        function cmenu1(app, obj, e)
            pos = get(app.SelectedObj, 'userdata');
            x = app.Tracker.classdata(pos(1)).Par(pos(2)).Data(1:app.scrol_index,2);
            y = app.Tracker.classdata(pos(1)).Par(pos(2)).Data(1:app.scrol_index,3);
            set(app.pl_t, 'XData', x, 'YData', y, 'Marker', 'none', 'color', app.Tracker.coll(pos(1),:), 'LineStyle', '-');
        end
        function cmenu2(app, obj, e)
            app.tableGUI();
        end
        function cmenu3(app, obj, e)
            pos = get(app.SelectedObj, 'userdata');
            app.Tracker.PlotTrajectory(pos(1),pos(2), app.scrol_index);
        end
        function cmenu4(app, obj, e)
            pos = get(app.SelectedObj, 'userdata');
            app.Tracker.PlotMSD(pos(1),pos(2));
        end
        function click(app, obj, e)
%             if e.Button == 1
                app.SelectedObj = [];
                app.renewform();
%             end
        end
    end
    methods (Access = private)% Basic functions
        function pos = takepos(app,obj)
            aa = get(obj, 'unit');
            set(obj, 'unit', 'pixels');
            pos = get(obj, 'position');
            set(obj, 'unit', aa);
        end
        function l = logic(app, aa)
            l = 0;
            switch aa
                case 'on'
                    l = 1;
                case 'off'
                    l = 0;
            end
        end
        function seticons(app, icon, obj)
            ss = size(icon);
            pos = app.takepos(obj);
            r1 = pos(4)/ss(1);
            r2 = pos(3)/ss(2);
            if r1 < r2
                imm = imresize(icon, r1);
            else
                imm = imresize(icon, r2);
            end
            set(obj, 'CData', imm);
        end
        function loadimages(app)
            if exist('icons/restartneed.png','file') > 0
                app.icons.restartneed = imread('icons/restartneed.png');
            else
                app.icons.restartneed = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/reclassifyneed.png','file') > 0
                app.icons.reclassifyneed = imread('icons/reclassifyneed.png');
            else
                app.icons.reclassifyneed = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/mPosTracker.png','file') > 0
                app.icons.logo = imread('icons/mPosTracker.png');
            else
                app.icons.logo = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/start.png','file') > 0
                app.icons.start = imread('icons/start.png');
            else
                app.icons.start = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/pause.png','file') > 0
                app.icons.pause = imread('icons/pause.png');
            else
                app.icons.pause = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/stop.png','file') > 0
                app.icons.stop = imread('icons/stop.png');
            else
                app.icons.stop = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/zoom_in.png','file') > 0
                app.icons.zoomin = imread('icons/zoom_in.png');
            else
                app.icons.zoomin = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/zoom_out.png','file') > 0
                app.icons.zoomout = imread('icons/zoom_out.png');
            else
                app.icons.zoomout = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/pan.png','file') > 0
                app.icons.pan = imread('icons/pan.png');
            else
                app.icons.pan = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/posfinder.png','file') > 0
                app.icons.posfinder = imread('icons/posfinder.png');
            else
                app.icons.posfinder = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/video.png','file') > 0
                app.icons.video = imread('icons/video.png');
            else
                app.icons.video = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/classify.png','file') > 0
                app.icons.classify = imread('icons/classify.png');
            else
                app.icons.classify = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/fft.png','file') > 0
                app.icons.fft = imread('icons/fft.png');
            else
                app.icons.fft = uint8(128*ones(64, 64, 3));
            end
            %=============================================
            if exist('icons/info.png','file') > 0
                app.icons.info = imread('icons/info.png');
            else
                app.icons.info = uint8(128*ones(64, 64, 3));
            end  
            %=============================================
            if exist('icons/continue.png','file') > 0
                app.icons.continue = imread('icons/continue.png');
            else
                app.icons.continue = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/cross.png','file') > 0
                app.icons.cross = imread('icons/cross.png');
            else
                app.icons.cross = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/question.png','file') > 0
                app.icons.question = imread('icons/question.png');
            else
                app.icons.question = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/caution.png','file') > 0
                app.icons.caution = imread('icons/caution.png');
            else
                app.icons.caution = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/icon.png','file') > 0
                app.icons.icon = imread('icons/icon.png');
            else
                app.icons.icon = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/help.png','file') > 0
                app.icons.help = imread('icons/help.png');
            else
                app.icons.help = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/restart.png','file') > 0
                app.icons.restart = imread('icons/restart.png');
            else
                app.icons.restart = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/inArea.png','file') > 0
                app.icons.inArea = imread('icons/inArea.png');
            else
                app.icons.inArea = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/plotNumPar.png','file') > 0
                app.icons.PlotNumPar = imread('icons/plotNumPar.png');
            else
                app.icons.PlotNumPar = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/PlotVCell.png','file') > 0
                app.icons.PlotVCell = imread('icons/PlotVCell.png');
            else
                app.icons.PlotVCell = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
            if exist('icons/PlotPairCol.png','file') > 0
                app.icons.PlotPairCol = imread('icons/PlotPairCol.png');
            else
                app.icons.PlotPairCol = uint8(128*ones(64, 64, 3));
            end          
            %=============================================
        end
        function setsld1(app)
            set(app.sld1, 'min', 1, 'max', length(app.Tracker.FrameN), 'Value', 1,...
            'SliderStep',[1/length(app.Tracker.FrameN), 10/length(app.Tracker.FrameN)], 'enable','on');
        end
        function setpanels(app,t)
            if t == 0
                set(app.p0, 'visible', 'on')
                set(app.p1, 'visible', 'off')
                set(app.p2, 'visible', 'off')
                set(app.p3, 'visible', 'off')
                set(app.p4, 'visible', 'off')
            else
                set(app.p0, 'visible', 'off')
                set(app.p1, 'visible', 'on')
                set(app.p2, 'visible', 'on')
                set(app.p3, 'visible', 'on')
                set(app.p4, 'visible', 'on')
            end
        end
        function addMsg(app, stt)
            set(app.statusMsg, 'string', stt);
        end
        function createobjs(app)
            app.Tracker.CalcRecPar();
        end
        function zoomButtonReset(app)
            set(app.zoomIn_btn, 'value', 0);
            set(app.zoomOut_btn, 'value', 0);
            set(app.pan_btn, 'value', 0);
            zoom(app.h,'off');
            pan(app.h,'off');
        end
        function l = isSaved(app)
            l = 0;
            if app.Tracker.save_project_l == 1
                l = 1;
            else
                l = 0;
            end
        end
        function generatesideform(app)
            
            chan = {'Red', 'Green', 'Blue'};
            tf = {'False', 'True'};
% 
            dt = {'Project Name', app.Tracker.ProjectName};
%             
            dt = [dt; {'Is the Project Saved?',tf{(app.Tracker.save_project_l + 1)}}];
                
            dt = [dt; {'Project File Name', app.Tracker.save_project_file}];
            dt = [dt; {'Project File Path', app.Tracker.save_project_path}];
            dt = [dt; {'Video File Name',app.Tracker.vid_filename}];
            dt = [dt; {'Video Color Mode',app.Tracker.video.videoFormat}];
            dt = [dt; {'Video Color Channel', chan{app.Tracker.Channel}}];
            dt = [dt; {'Selected Image Size W x H',[ num2str(app.Tracker.CamSize(2)) ' X ' num2str(app.Tracker.CamSize(1))]}];
            dt = [dt; {'Raw Image Size W x H', [ num2str(app.Tracker.video.width) ' X ' num2str(app.Tracker.video.height)]}];
            if ~isempty(app.inArea)
                dt = [dt; {'Interesting Area', [ num2str(app.inArea(1)) ', ' num2str(app.inArea(2)) ', ' num2str(app.inArea(3)) ', ' num2str(app.inArea(4)) ]}];
            end
            dt = [dt; {'Use inverted image',tf{(app.Tracker.invertedim + 1)}}];
            dt = [dt; {'Raw Frame Number',num2str(app.Tracker.video.NumberOfFrames)}];
            dt = [dt; {'Selected Frame Number',num2str(length(app.Tracker.FrameN))}];
            dt = [dt; {'Current Frame Number',num2str(app.Tracker.current_index)}];
            dt = [dt; {'Selected Frame Rate',num2str(app.Tracker.FrameRate)}];
            dt = [dt; {'Raw Frame Rate',num2str(app.Tracker.video.FrameRate)}];
            
            dt = [dt; {'Are positions calculated?',tf{(app.Tracker.checkHamData() + 1)}}];
            dt = [dt; {'Is Recalculation Need?',tf{(app.Tracker.recalculation_l + 1)}}];
            dt = [dt; {'Are positions Classified?',tf{(app.Tracker.checkClassData() + 1)}}];
            dt = [dt; {'Is Reclassification Need?',tf{(app.Tracker.reclassification + 1)}}];
            
            if app.Tracker.checkClassData()
                cc = {'1st. Kind (Red)', '2nd. Kind (Green)', '3rd. Kind (Blue)'};
                tnum = 0;
                for i = 1 : app.Tracker.tursay
                   dt = [dt; {cc{i}, num2str(app.Tracker.ParSay(app.Tracker.current_index,i+1))}];
                   tnum = tnum + app.Tracker.ParSay(app.Tracker.current_index,i+1);
                end
                dt = [dt; {'Number of Particles', num2str(tnum)}];
            end
                
                set(app.sideform, 'data', dt);
                
%                 inspect(app.sideform)
        end
        function par = CalcSixFold(app, j, point, vertex, vdata, V, C)
            par = 0;
            komsu = [];
            for i = 1 : length(vdata(:,1))
                if i ~= j
                    vertex2 = [V(C{i},1), V(C{i},2)];
                    count = 0;
                    for t1 = 1 : length(vertex)
                        for t2 = 1 : length(vertex2)
                            if vertex(t1,1) == vertex2(t2,1) && vertex(t1,2) == vertex2(t2,2)
                                count = count + 1;
                            end
                        end
                    end
                    if count > 1
                        komsu = [komsu; vdata(i, 1), vdata(i, 2)];
                    end                     
                end
            end
%             disp(length(komsu));
            if ~isempty(komsu)
                ANGLEV = [];
                for t = 1 : length(komsu)
                    SX = komsu(t,1)-point(1);
                    SY = komsu(t,2)-point(2);
                    AngleV = atan(SY/SX);
                    ANGLEV = [ANGLEV,AngleV];
                end
                A = 0;
                for w = 1 : length(ANGLEV)
                    Te = exp(6*1i*ANGLEV(w));
                    A = A + Te;
                end
                par = abs((1/6)*A);
            end
        end
        function plot_seepar(app)

            data = [];
            for k = 1 : app.Tracker.tursay
                for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                    x = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,2);
                    y = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,3);
                    if ~isnan(x) && ~isnan(y) && ~isinf(x) && ~isinf(y)
                        data = [data; x, y, app.Tracker.coll(k,:),app.Tracker.RecPar(k), k, k2];
                    end
                end
            end
            if ~isempty(data)
                app.pl = scatter(app.ax, data(:,1),data(:,2));
                set(app.pl, 'SizeData', data(:,6), 'CData', data(:,3:5), 'Marker', '+');
                for i = 1 : length(data(:,1))
                    app.rec(i) = rectangle(app.ax);
                    set(app.rec(i),'position', [data(i,1)-app.Tracker.RecPar(data(i,7))/2,...
                             data(i,2)-app.Tracker.RecPar(data(i,7))/2,...
                             app.Tracker.RecPar(data(i,7)),...
                             app.Tracker.RecPar(data(i,7))],....
                    'edgecolor', data(i,3:5));
                    set(app.rec(i), 'ButtonDownFcn', @app.pointselected, 'PickableParts', 'all', 'uicontextmenu', app.c_menu, 'userdata', [data(i,7), data(i,8)]);
                end
            else
                c = app.qBox(3, 'There is no data');
            end
        end
        function plot_seeall(app)
            i = 0;
            for k = 1 : app.Tracker.tursay
                data = [];
                for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                    x = app.Tracker.classdata(k).Par(k2).Data(1:app.scrol_index,2);
                    y = app.Tracker.classdata(k).Par(k2).Data(1:app.scrol_index,3);
                    if ~isnan(x(end)) && ~isnan(y(end))
                    data = [data; x, y];
                    i = i + 1;
                    app.pl_t(i) = plot(app.ax, 0, 0);
                    set(app.pl_t(i), 'XData', x, 'YData', y, 'Marker', 'none', 'color', app.Tracker.coll(k,:), 'LineStyle', '-');
                    end
                end
            end
        end
        function plot_see(app)
            app.pl = plot(app.ax,0,0);
            set(app.pl, 'XData', app.Tracker.HamData(app.scrol_index).Par(:,1), 'YData', app.Tracker.HamData(app.scrol_index).Par(:,2), 'Marker', '*', 'color', 'r', 'LineStyle', 'none');
        end
        function plot_vcells(app)
            if ~isempty(app.inArea) && app.Tracker.partnum(app.scrol_index) > 2
                vdata = [];
                for k = 1 : app.Tracker.tursay
                    for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                        x = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,2);
                        y = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,3);
                        if ~isnan(x) && ~isnan(y) && ~isinf(x) && ~isinf(y)
                            vdata = [vdata; x, y];
                        end
                    end
                end
                if ~isempty(vdata)
                [V,C] = voronoin([vdata(:,1), vdata(:,2)]);
                say = 0;
                delete(app.pat);
                    for j = 1 : length(vdata(:,1))
                        point = vdata(j,:);
                        vertex = [V(C{j},1), V(C{j},2)];
                        if point(1) >= app.inArea(1) && point(1) <= app.inArea(1) + app.inArea(3) - 1 ...
                           && point(2) >= app.inArea(2)&& point(2) <= app.inArea(2) + app.inArea(4) - 1
                            if all(all(~isinf(vertex))) ...
                                    && all(all(vertex(:,1)>=1)) && all(all(vertex(:,1)<=app.Tracker.CamSize(2))) ...
                                    && all(all(vertex(:,2)>=1)) && all(all(vertex(:,2)<=app.Tracker.CamSize(1)))

                                f = 1:length(vertex(:,1));
                                say = say + 1;
                                app.pat(say) = patch(app.ax);
                                if app.logic(get(app.v_check, 'checked')) == 0
                                    set(app.pat(say), 'Faces',f,'Vertices',vertex,'FaceColor','none','EdgeColor','yellow');
                                else
                                    par = app.CalcSixFold(j, point, vertex, vdata, V, C);
                                    col = 'w';
                                    if par < 0.9
                                        col = 'b';
                                    else
                                        col = 'r';
                                    end
                                    set(app.pat(say), 'Faces',f,'Vertices',vertex,'FaceColor',col,'EdgeColor','yellow');
                                end

                            end
                        end
                    end
                else
                    c = app.qBox(3, 'There is no data');
                end
            else

            end
        end
        function plot_HamData_see(app)
            app.pl = plot(app.ax,0,0);
            set(app.pl, 'XData', app.Tracker.HamData(app.scrol_index).Par(:,1), 'YData', app.Tracker.HamData(app.scrol_index).Par(:,2), 'Marker', '*', 'color', 'r', 'LineStyle', 'none');
        end
    end
    methods (Access = private)%main loop
        function renewform(app)
            if app.Tracker.isexistvideo()
                app.setpanels(1);

                objs = [app.m_openp, app.m_savep, app.m_closep...
                    , app.m_project, app.m_newp...
                    , app.m_exit, app.m_last, app.m_help, app.m_about];
                set(objs, 'enable', 'on');
                
                if app.Tracker.checkHamData()
                    set(app.classify_btn, 'enable', 'on');
                else
                    set(app.classify_btn, 'enable', 'off');
                end
                

                app.draw();
                app.generatesideform();
            else
                app.setpanels(0);

                objs = [app.m_savep, app.m_closep];
                set(objs, 'enable', 'off');

                objs = [app.m_project, app.m_openp, app.m_newp, app.m_exit, app.m_last, app.m_help, app.m_about];
                set(objs, 'enable', 'on');                
            end
            
        end
        function draw(app)
            
            app.Tracker.takeim_fft(app.scrol_index);

            delete(app.pat);
            delete(app.rec);
            delete(app.pl);
            reset(app.pl_t);
            reset(app.rec_inArea);
            reset(app.im);
            app.SelectedObj=[];
            
            if ~get(app.fft_btn, 'value')
                set(app.im, 'CData', app.Tracker.imFull);
                set(app.ax, 'nextplot', 'add');
                if ~get(app.PlotVCell_btn, 'value')
                    set(app.im, 'UIContextMenu', app.n_menu);
                    set(app.im, 'ButtonDownFcn', @app.click);
                else
                    set(app.im, 'UIContextMenu', app.v_menu);
                    set(app.im, 'ButtonDownFcn', []);
                end
            else
                set(app.im, 'CData', app.Tracker.imFull_fft);
                set(app.im, 'UIContextMenu', app.fft_menu);
                set(app.im, 'ButtonDownFcn', []);
            end
            
            if ~get(app.fft_btn, 'value')
                if app.Tracker.checkHamData()
                    if app.Tracker.checkClassData()
                        if ~get(app.PlotVCell_btn, 'value')
                            if app.logic(get(app.n_seepar, 'checked')) == 1
                                app.plot_seepar();
                            elseif app.logic(get(app.n_seeall, 'checked')) == 1
                                app.plot_seeall();
                            else
                                app.plot_see();
                            end
                        else
                            app.plot_vcells();
                        end
                        set(app.statusMsg, 'string','All results are calculated!');
                         if ~isempty(app.inArea) && app.logic(get(app.n_seeinArea, 'checked')) == 1
                            set(app.rec_inArea,'position', app.inArea, 'edgecolor', 'y'); 
                        end                       
                    else
                        app.plot_HamData_see();
                        set(app.statusMsg, 'string','Please, Track and Classfy the positions!');
                    end
                else
                    set(app.statusMsg, 'string','Please, calculate positions by using PosFinder!');
                end
            else
            end
            

            set(app.ax, 'nextplot', 'replace');
            
        end
    end
    methods (Access = private)%GUI Functions
        function set_ROI(app)
            
            channel = app.Tracker.Channel;
            Start_i = app.Tracker.Start_i;
            Step_i = app.Tracker.Step_i;
            End_i = app.Tracker.End_i;
            Frate = app.Tracker.FrameRate;
            FrameN = app.Tracker.FrameN;
            index = app.scrol_index;
            prepare();

            ss = size(app.Tracker.frame);
            mvec = zeros(1,2);
            selectedVec1 = zeros(1,2);
            selectedVec2 = zeros(1,2);
            save_rect12 = zeros(1,2);
            click = zeros(1,1);
            rect = zeros(1,4);
            RefMod = uint8(1);
            cent = zeros(1,2);
            conpar = app.Tracker.pix2mic;
            
            rect(1) = app.Tracker.UserSize(3);
            rect(2) = app.Tracker.UserSize(1);
            rect(3) = app.Tracker.UserSize(4) - app.Tracker.UserSize(3) + 1;
            rect(4) = app.Tracker.UserSize(2) - app.Tracker.UserSize(1) + 1;
            
            if rect(3) < ss(2) && rect(4) < ss(1)
                click = 2;
            end

            [d, btn1, btn2, axx, xe, ye, we, he, r1, r2, sld, Si, Ti, Ei, R, G, B, pix2mic,fr,checkbox] = generateForm();
            
            RGBinit();
            setsld();
            set(sld, 'value', index);
            draw();

            uiwait(d);
            function [d, btn1, btn2, axx, xe, ye, we, he, r1, r2, sld, Si, Ti, Ei, R, G, B, pix2mic,fr,checkbox] = generateForm()
                pos = app.takepos(app.h);
                w = 600;
                he = 400;
                px = pos(1) + pos(3)/2-w/2;
                py = pos(2) + pos(4)/2-he/2;
                d = figure('Units','pixels'...
                    ,'Position',[px py w he]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'set Video Properties'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'WindowButtonMotionFcn', @mouseMove...
                    ,'WindowButtonDownFcn', @mouseClick...
                    ,'WindowButtonUpFcn', @mouseUpClick,'color', app.WinBackgroundColor);%
                
                pp0 = uipanel(d, 'Units','normalized','Position', [0.0 0.0 0.6 1.0],'title','Original Camera Image', 'BackgroundColor', app.PanelBackgroundColor);
                pp1 = uipanel(d, 'Units','normalized','Position', [0.6 0.0 0.4 1.0],'title','Camera Parameters', 'BackgroundColor', app.PanelBackgroundColor);
                
                axx = axes('parent', pp0, 'Units','normalized', 'Position', [0.00 0.17 1 0.75]);
                sld = uicontrol(pp0,'style','slider','callback', @call_sld, 'BackgroundColor', [1 1 1],...
                    'Units','normalized', 'Position', [0.00 0.03 1 0.05], 'enable','off');
                
                pos = app.takepos(pp1);
                uicontrol(pp1, 'style','text' , 'String', ['Full Frame Size : Width ' num2str(app.Tracker.video.width)  ', Height ' num2str(app.Tracker.video.height)]...
                    ,'HorizontalAlignment', 'left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-40 pos(3) 20],'BackgroundColor', [1 1 1]);               

                uicontrol(pp1, 'style','text' , 'String', 'ROI Size','HorizontalAlignment', 'Left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-60 60 20],'BackgroundColor', [1 1 1]);
                btn2 = uicontrol(pp1, 'Callback', @reset , 'String','reset ROI',...
                    'Units','pixels', 'Position', [80 pos(4)-55 70 18],'BackgroundColor', app.WinBackgroundColor);
                xt = uicontrol(pp1, 'style','text' , 'String', 'X :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-80 20 20],'BackgroundColor', [1 1 1]);
                yt = uicontrol(pp1, 'style','text' , 'String','Y :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-100 20 20],'BackgroundColor', [1 1 1]);
                wt = uicontrol(pp1, 'style','text' , 'String','Width :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10+80 pos(4)-80 40 20],'BackgroundColor', [1 1 1]);
                ht = uicontrol(pp1, 'style','text' , 'String','Height :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10+80 pos(4)-100 40 20],'BackgroundColor', [1 1 1]);
                
                xe = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(1)),...
                    'Units','pixels', 'Position', [30 pos(4)-80 50 20]);
                ye = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(2)),...
                    'Units','pixels', 'Position', [30 pos(4)-100 50 20]);
                we = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(3)),...
                    'Units','pixels', 'Position', [130 pos(4)-80 50 20]);
                he = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(4)),...
                    'Units','pixels', 'Position', [130 pos(4)-100 50 20]);
                

                uicontrol(pp1, 'style','text' , 'String', 'Reference Point For Center','HorizontalAlignment', 'Left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-125 pos(3) 20],'BackgroundColor', [1 1 1]);
                r1 = uicontrol(pp1, 'style', 'radiobutton' , 'String', 'at corner', 'value', 1,'BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [30 pos(4)-140 70 20], 'callback', @rbutton1);        
                r2 = uicontrol(pp1, 'style', 'radiobutton' , 'String', 'at center','BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [120 pos(4)-140 70 20], 'callback', @rbutton2);    
                
                
                
                fr = uicontrol(pp1, 'style','text' , 'String', ['Frame Rate : ' num2str(Frate)],'HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-160 pos(3) 20],'BackgroundColor', [1 1 1],'FontWeight', 'bold');                
                
                uicontrol(pp1, 'style','text' , 'String', ['Max. Frame Number : ' num2str(app.Tracker.nFrame)],'HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-180 pos(3) 20],'BackgroundColor', [1 1 1],'FontWeight', 'bold');  
                uicontrol(pp1, 'style','text' , 'String', 'Starting Frame Index','HorizontalAlignment', 'left',...
                    'Units','pixels', 'Position', [10 pos(4)-200 120 20],'BackgroundColor', [1 1 1]);
                uicontrol(pp1, 'style','text' , 'String', 'Step of Frame','HorizontalAlignment', 'left',...
                    'Units','pixels', 'Position', [10 pos(4)-220 120 20],'BackgroundColor', [1 1 1]); 
                uicontrol(pp1, 'style','text' , 'String', 'End Frame Index','HorizontalAlignment', 'left',...
                    'Units','pixels', 'Position', [10 pos(4)-240 120 20],'BackgroundColor', [1 1 1]);                
                
                Si = uicontrol(pp1, 'style','edit','Callback', @call_start_i , 'String',app.Tracker.Start_i,...
                    'Units','pixels', 'Position', [140 pos(4)-200 50 20],'BackgroundColor', [1 1 1]);
                Ti = uicontrol(pp1, 'style','edit','Callback', @call_step_i , 'String',app.Tracker.Step_i,...
                    'Units','pixels', 'Position', [140 pos(4)-220 50 20],'BackgroundColor', [1 1 1]);
                Ei = uicontrol(pp1, 'style','edit','Callback', @call_end_i , 'String',app.Tracker.End_i,...
                    'Units','pixels', 'Position', [140 pos(4)-240 50 20],'BackgroundColor', [1 1 1]);
                
                uicontrol(pp1, 'style','text' , 'String', ['Video Format : ' app.Tracker.video.videoFormat],'HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-260 pos(3) 20],'BackgroundColor', [1 1 1],'FontWeight', 'bold');                 
                uicontrol(pp1,'Units','pixels', 'Position', [10 pos(4)-280 90 20],'style','text','string', 'Color Channels','HorizontalAlignment', 'left','BackgroundColor', [1 1 1]);
                R= uicontrol(pp1,'Units','pixels', 'Position', [100 pos(4)-275 30 20],'style','radiobutton','string', 'R','enable','on','callback',@call_R,'BackgroundColor', [1 1 1]);
                G= uicontrol(pp1,'Units','pixels', 'Position', [140 pos(4)-275 30 20],'style','radiobutton','string', 'G','enable','on','callback',@call_G,'BackgroundColor', [1 1 1]);
                B= uicontrol(pp1,'Units','pixels', 'Position', [180 pos(4)-275 30 20],'style','radiobutton','string', 'B','enable','on','callback',@call_B,'BackgroundColor', [1 1 1]);                
                
                checkbox = uicontrol(pp1, 'style', 'checkbox', 'string', 'Use Inverted Image',...
                        'HorizontalAlignment' , 'left', 'BackgroundColor', [1 1 1], 'value', app.Tracker.invertedim, ...
                        'Units','pixels', 'Position', [10 pos(4)-295 pos(3) 20], 'callback', @call_checkbox);
                    
               
                uicontrol(pp1,'Units','pixels', 'Position', [10 pos(4)-320 170 20],'style','text','string', 'Conversation Parameter','HorizontalAlignment', 'left','BackgroundColor', [1 1 1],'FontWeight', 'bold');
                uicontrol(pp1,'Units','pixels', 'Position', [10 pos(4)-340 50 20],'style','text','string', '1 pixel = ','HorizontalAlignment', 'left','BackgroundColor', [1 1 1]);
                pix2mic = uicontrol(pp1, 'style','edit','Callback', @call_pix2mic , 'String',app.Tracker.pix2mic,...
                    'Units','pixels', 'Position', [60 pos(4)-340 50 20],'BackgroundColor', [1 1 1]);
                uicontrol(pp1,'Units','pixels', 'Position', [110 pos(4)-340 50 20],'style','text','string', ' microns','HorizontalAlignment', 'left','BackgroundColor', [1 1 1]);
                
                btn1 = uicontrol(pp1, 'Callback', @ok , 'String','set Parameters',...
                'Units','pixels', 'Position', [pos(3)/2-75 10 150 40],'BackgroundColor', app.WinBackgroundColor);
              
            end
            function prepare()
                FrameN = Start_i :Step_i : End_i;
                Frate = app.Tracker.video.FrameRate;
            end
            function RGBinit()
                switch channel
                    case 1
                        set(R, 'value', 1);
                        set(G, 'value', 0);
                        set(B, 'value', 0);
                    case 2
                        set(R, 'value', 0);
                        set(G, 'value', 1);
                        set(B, 'value', 0);
                    case 3
                        set(R, 'value', 0);
                        set(G, 'value', 0);
                        set(B, 'value', 1);
                end
                switch app.Tracker.ColorMod
                    case 0
                        set(R, 'Enable', 'on');
                        set(G, 'Enable', 'off');
                        set(B, 'Enable', 'off');
                    case 1
                        set(R, 'Enable', 'on');
                        set(G, 'Enable', 'on');
                        set(B, 'Enable', 'on');
                end                
            end
            function call_R(s, e)
                set(R,'value',1);
                set(G,'value',0);
                set(B,'value',0);
                channel = 1;
                draw();
            end
            function call_G(s, e)
                set(R,'value',0);
                set(G,'value',1);
                set(B,'value',0);
                channel = 2;
                draw();
            end
            function call_B(s, e)
                set(R,'value',0);
                set(G,'value',0);
                set(B,'value',1);
                channel = 3;
                draw();
            end
            function call_start_i(s,e)
                    aa = str2double(get(Si, 'string'));
                    Start_i = 1;
                    if ~isnan(aa)
                        if aa <= End_i && aa > 0
                            Start_i = aa;
                        end
                    end
                    set(Si, 'string', Start_i);
                    prepare();
                    setsld();
                    index = 1;
                    draw();
            end
            function call_end_i(s,e)
                    aa = str2double(get(Ei, 'string'));
                    End_i = app.Tracker.nFrame;
                    if ~isnan(aa)
                        if aa <= app.Tracker.nFrame && aa >= Start_i
                            End_i = aa;
                        end
                    end
                    set(Ei, 'string', End_i);
                    prepare();
                    setsld();
                    index = 1;
                    draw();
            end
            function call_step_i(s,e)
                    aa = str2double(get(Ti, 'string'));
                    Step_i = 1;
                    if ~isnan(aa)
                        if aa <= app.Tracker.End_i && aa <= End_i - Start_i
                            Step_i = aa;
                        end
                    end
                    prepare();
                    setsld();
                    index = 1;
                    set(Ti, 'string', Step_i);
                    set(fr, 'string', ['Frame Rate : ' num2str(Frate)]);
                    draw();
            end
            function call_sld(s,e)
                aa = round( get(sld,'Value'));
                index = aa;
                draw();
            end
            function call_pix2mic(s,e)
                    aa = str2double(get(pix2mic, 'string'));
                    conpar = app.Tracker.pix2mic;
                    if ~isnan(aa)
                        conpar = aa;
                    end
                    set(pix2mic, 'string', conpar);
            end
            function setsld()
                set(sld, 'min', 1, 'max', length(FrameN), 'Value', 1,...
                'SliderStep',[1/length(FrameN), 10/length(FrameN)], 'enable','on');
            end
            function mouseMove(s,e)
                mvec = getPoint();
                switch click 
                    case 0
                        if insideRect(mvec, [1, 1, ss(2), ss(1)])
                            set(d,'Pointer','cross');
                        else
                            set(d,'Pointer','arrow');
                        end
                    case 1
                        selectedVec2 = mvec;
                        draw();
                    case 2
                        if insideRect(mvec, rect)
                            set(d,'Pointer','fleur');
                        else
                            set(d,'Pointer','arrow');
                        end
                    case 3
                        selectedVec2 = mvec;
                        draw();
                end

            end
            function mouseClick(s,e)
                mvec = getPoint();
                switch click 
                    case 0
                        selectedVec1 = mvec;
                        click = 1;                
                    case 1

                    case 2
                        if insideRect(mvec, rect) == 1
                            selectedVec1 = mvec;
                            save_rect12 = rect(1:2);
                            click = 3;
                        else
                            if insideRect(mvec, [1, 1 , ss(2), ss(1)])
                                click = 0;
                                rect = zeros(1,4);
                                draw();                        
                            end
                        end
                    case 3

                end

            end
            function t = insideRect(v, area)
                t = 0;
                if v(1) > area(1) && v(1) < area(1) + area(3) - 1
                    if v(2) > area(2) && v(2) < area(2) + area(4) - 1
                        t = 1;
                    end
                end

            end
            function mouseUpClick(~,~)
                mvec = getPoint();
                switch click 
                    case 0

                    case 1
                        click = 2;
                    case 2

                    case 3
                        click = 2;

                end
            end
            function draw()
                frame = takeimage(index);%buraya bakkkk!!!!!!!!!!!!!
                image(frame)
                if click == 1
                    rect = calcRect();
                end
                if click == 3
                    rect = translation();
                end

                rect = floor(rect);
                if RefMod == 1
                    cent = rect(1:2);
                else
                    cent = [rect(1)+(rect(3)/2), rect(2) + (rect(4)/2)];
                end
                
                hold on
                if click == 0
                    rectangle('Position',rect,'EdgeColor','r')
                else
%                     plotv(cent' ,'-y')
                    line([0 cent(1)],[0 cent(2)],'Color','y')
                    rectangle('Position',rect,'EdgeColor','y')
                    plot(cent(1), cent(2), 'oy')
                    plot(cent(1), cent(2), '.y')
                end
                hold off
                axis equal 

                set(xe, 'string', cent(1));
                set(ye, 'string', cent(2));
                set(we, 'string', rect(3));
                set(he, 'string', rect(4));

            end
            function frame = takeimage(i)
                index = i;
                frame = read(app.Tracker.video,FrameN(index));
            end
            function r = translation()
                vec = selectedVec2 - selectedVec1;
                sPoint = save_rect12(1:2) + vec;
                if abs(sPoint(1)) + rect(3) < ss(2) && abs(sPoint(2)) + rect(4) < ss(1) ...
                        && sPoint(1) > 0 && sPoint(2) > 0
                    r = [sPoint(1), sPoint(2), rect(3), rect(4)];
                else
                    r = rect;
                end

            end
            function r = calcRect()
                vec = selectedVec2 - selectedVec1;
                if abs(selectedVec2(1)) < ss(2) && abs(selectedVec2(2)) < ss(1) ...
                        && selectedVec2(1) > 0 && selectedVec2(2) > 0
                    if vec(1) < 0
                        if vec(2) < 0
                            sPoint = selectedVec2;
                        else 
                            sPoint = selectedVec1 + [vec(1), 0];
                        end
                    else
                        if vec(2) < 0
                            sPoint = selectedVec1 + [0, vec(2)];
                        else 
                            sPoint = selectedVec1;
                        end
                    end
                    r = [sPoint(1), sPoint(2), abs(vec(1)), abs(vec(2))];
                else
                    r = rect;
                end

            end
            function enter(~, ~)
                x = round(str2double(get(xe,'string')));
                y = round(str2double(get(ye,'string')));
                w = round(str2double(get(we,'string')));
                h_= round(str2double(get(he,'string')));
                if ~isnan(x) && ~isnan(y) && ~isnan(w) && ~isnan(h_)
                    if RefMod == 1
                      if x > 0 && x + w - 1 <= ss(2) && w > 0 && h_>0 ...
                            && y > 0 && y + h_ -1 <=ss(1) && w<=ss(2) && h_<=ss(1)
                        rect(1) = x;
                        rect(2) = y;
                        rect(3) = w;
                        rect(4) = h_;
                      end              
                    else
                      if x - w/2 > 0 && x + w/2 <= ss(2) && w > 0 && h_>0 ...
                            && y - h_/2 > 0 && y + h_/2 <= ss(1) && w <= ss(2) && h_ <= ss(1)
                        rect(1) = x - w/2;
                        rect(2) = y - h_/2;
                        rect(3) = w;
                        rect(4) = h_;
                      end    
                    end

                end
                draw();
            end
            function reset(~,~)
                click = 0;
                rect = [1, 1, app.Tracker.video.width, app.Tracker.video.height];
                draw();
            end
            function c = getPoint()
                c = get (axx, 'CurrentPoint');
                c = [c(1,1), c(1,2)];
            end
            function ok(~,~)
                k = 1;
                if app.Tracker.checkHamData() == 1
                    c = app.qBox(1, 'Calculated Positions are available. You must recalculate the psitions. Do you want to continue?');
                    if ~isnan(c) && c == 1
                        k = 1;
                        app.addMsg('ReCalculation of the positions is needed!');
                        app.Tracker.recalculation_l = 1;
                        app.Tracker.recalculation();
                    else
                        k = 0;
                    end
                end
                if k == 1
                    app.Tracker.UserSize(1) = floor(rect(2));
                    app.Tracker.UserSize(2) = floor(rect(2)) + floor(rect(4)) - 1;
                    app.Tracker.UserSize(3) = floor(rect(1));
                    app.Tracker.UserSize(4) = floor(rect(1)) + floor(rect(3)) - 1;
                    app.Tracker.setAreas();
                    app.Tracker.Channel = channel;
                    app.Tracker.Start_i = Start_i;
                    app.Tracker.Step_i = Step_i;
                    app.Tracker.End_i = End_i;
                    app.scrol_index = index;  
                    app.Tracker.save_project_l = 0;
                    app.Tracker.pix2mic = conpar;
                end

                delete(d);
            end
            function rbutton1(s,~)
                set(r1, 'value', 1);
                set(r2, 'value', 0);
                RefMod = 1;
                draw();
            end
            function rbutton2(s,~)
                set(r1, 'value', 0);
                set(r2, 'value', 1);
                RefMod = 2;
                draw();
            end
            function call_checkbox(~,~)
                aa = get(checkbox, 'value');
                if aa == 1
                    app.Tracker.invertedim = 1;
                else
                    app.Tracker.invertedim = 0;
                end
                draw();
            end
        end
        function c = qBox(app, tur, msg)
            c = NaN;
            [d, m, text, yes, no] = generateForm();
            init();
            
%             inspect(m)
            
            uiwait(d);
            function [d, m, text, yes, no] = generateForm()
                pos = app.takepos(app.h);
                px = pos(1) + pos(3)/2-300/2;
                py = pos(2) + pos(4)/2-150/2;
                d = figure('Units','pixels'...
                    ,'Position',[px py 300 150]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'Question...'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'CloseRequestFcn', @closeWin...
                    ,'color', [1 1 1]);%

%                 axx = axes('parent', d, 'Units','pixels', 'Position', [5 65 80 80]);
                m = uicontrol(d,'style','checkbox','enable', 'inactive',...
                    'BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [25 70 60 60]);
                
                text = uicontrol(d,'style','text','string', msg,...
                    'HorizontalAlignment'	, 'left','BackgroundColor', [1 1 1],...
                    'Units','char', 'Position', [20 6 34 3]);

                yes = uicontrol(d, 'Callback', @call_yes , 'String','Yes',...
                    'Units','pixels', 'Position', [45 18 90 40]);%,'BackgroundColor', [1 1 1]

                no = uicontrol(d, 'Callback', @call_no , 'String','No',...
                    'Units','pixels', 'Position', [165 18 90 40]);%

            end
            function init()
                set(text, 'string', msg);
                switch tur
                    case 1
                        app.seticons(app.icons.cross, m);
                    case 2
                        app.seticons(app.icons.question, m);
                    case 3
                        app.seticons(app.icons.caution, m);
                end
            end
            function call_yes(~,~)
                c = 1;
                delete(d);
            end
            function call_no(~,~)
                c = 0;
                delete(d);
            end
            function closeWin(~, ~)
                c = 0;
                delete(d);
            end
        end
        function [val, in] = set_th(app, th, s, index)
            val = NaN;
            in = NaN;
            [d, btn, s1, s2] = generateForm();
            function [d, btn, s1, s2] = generateForm()
                pos = app.takepos(app.h);
                px = pos(1) + pos(3)/2-400/2;
                py = pos(2) + pos(4)/2-400/2;
                d = figure('Units','Pixels'...
                    ,'Position',[px py 400 400]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'set Threshold'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off','color', [1 1 1]);

                btn = uicontrol(d, 'Callback', @ok , 'String',['set th as ' num2str(th)],...
                    'Units','normalized', 'Position', [(1-0.3)/2 0.02 0.3 0.1],'BackgroundColor', [1 1 1]);

                axes('parent', d, 'Position', [0.1 0.3 0.8 0.6]);

                s1 = uicontrol(d,'style','slider','callback', @draw,...
                'Units','normalized', 'Position', [0.1 0.16 0.8 0.05],'BackgroundColor', [1 1 1]);
                set(s1, 'min', 1, 'max', get(s,'max'), 'Value', index,...
                'SliderStep', get(s,'SliderStep'), 'enable','on');

                s2 = uicontrol(d,'style','slider','callback', @draw,...
                'Units','normalized', 'Position', [0.92 0.3 0.06 0.6],'BackgroundColor', [1 1 1]);
                set(s2, 'min', 0, 'max', 255, 'Value', th,...
                'SliderStep',[1/256, 10/256], 'enable','on');                
            end

            draw();

            uiwait(d);
            function draw(~,~)
                th = round( get(s2,'Value'));
                set(btn, 'String',['set th as ' num2str(th)]);
                index = round( get(s1,'Value'));
                app.Tracker.takeim(index);
                bw2 = app.Tracker.imFull;
                avg = mean(app.Tracker.imFull(:));
                bw2(bw2<avg)=avg;
                bw2 = (bw2-min(bw2(:)))/(max(bw2(:))-min(bw2(:)))*255;
                bw = bw2;
                bw(bw <= th) = 0;
                bw(bw > th) = 1;
                res = zeros(app.Tracker.CamSize(1), app.Tracker.CamSize(2), 3);
                r1 = app.Tracker.imFull + bw*255;
                r1(r1>255) = 255;
                r2 = app.Tracker.imFull - bw*255;
                r2(r2<0) = 0;
                res(:,:,1) = r1/255;
                res(:,:,2) = r2/255;
                res(:,:,3) = r2/255;
                image(res), colormap('default')
                title('set Threshold')
                axis equal
                hold off                
            end
            function ok(~,~)
%                 print(cgf,'Th_eps','-depsc2')
                val = th;
                in = index;
                delete(d);
            end
        end
        function posfinder(app)
            
            started = 0;

            [d, t, axx, m, pll, prr, sld, CalcMethod_pop, L_edit, msg, th_text, th_edit, Rout_edit, start_btn, stop_btn, PosFinder_btn, btn] = generateForm();
            
            init();

            uiwait(d);
            function [d, t, axx, m, pll, prr, sld, CalcMethod_pop, L_edit, msg, th_text, th_edit, Rout_edit, start_btn, stop_btn, PosFinder_btn, btn] = generateForm()
                pos = app.takepos(app.h);
                w = 600;
                he = 400;
                px = pos(1) + pos(3)/2-w/2;
                py = pos(2) + pos(4)/2-he/2;
                d = figure('Units','Pixels'...
                    ,'Position',[px py w he]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'PosFinder Properties'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'color', [1 1 1]);%
                
                t = timer('TimerFcn', @stepProcess, 'StartDelay', 0.2...
                ,'ExecutionMode', 'singleShot');
                
                pp0 = uipanel(d, 'Units','normalized','Position', [0.0 0.1 0.7 0.9],'title','Current Image', 'BackgroundColor', app.PanelBackgroundColor);
                pp1 = uipanel(d, 'Units','normalized','Position', [0.7 0.3 0.3 0.7],'title','Parameters', 'BackgroundColor', app.PanelBackgroundColor);
                pp2 = uipanel(d, 'Units','normalized','Position', [0.7 0.0 0.3 0.3],'title','Find Positions for All Images', 'BackgroundColor', app.PanelBackgroundColor);
                
                
                
                axx = axes('parent', pp0, 'Position', [0.00 0.17 1 0.75]);
                m = image(axx);
                set(axx, 'nextplot', 'add');
                pll = plot(axx,0,0);
                prr = rectangle(axx, 'Position',[0 0 0 0]);
                set(axx, 'nextplot', 'replace');
                
                sld = uicontrol(pp0,'style','slider','callback', @call_sld, 'BackgroundColor', [1 1 1],...
                    'Units','normalized', 'Position', [0.00 0.03 1 0.05]);

                
                uicontrol(pp1,'style','text','string', 'Method',...
                    'HorizontalAlignment'	, 'right',...
                    'Units','normalized', 'Position', [0.05 0.78 0.4 0.1],'BackgroundColor', [1 1 1]);

                CalcMethod_pop = uicontrol(pp1,'style','popupmenu','Callback', @callCalcMethod,...
                    'String', {'1-Centroid', '2-Radial Sym. (RSM)', '3-Partial RSM'},...
                    'Units','normalized', 'Position', [0.5 0.8 0.4 0.1],'BackgroundColor', [1 1 1]);

                uicontrol(pp1,'style','text','string', 'Ignored (Red) Area',...
                    'HorizontalAlignment'	, 'right',...
                    'Units','normalized', 'Position', [0.0 0.63 0.45 0.1],'BackgroundColor', [1 1 1]);

                L_edit = uicontrol(pp1,'style','edit',...
                    'HorizontalAlignment'	, 'center','Callback', @callL_edit, ...
                    'Units','normalized', 'Position', [0.5 0.65 0.4 0.1],'BackgroundColor', [1 1 1]);

                th_text = uicontrol(pp1,'style','pushbutton','string', 'Threshold ',...
                    'HorizontalAlignment'	, 'center','Callback', @callth_text,...
                    'Units','normalized', 'Position', [0.05 0.5 0.4 0.1],'BackgroundColor', [1 1 1]);
                th_edit = uicontrol(pp1,'style','edit',...
                    'HorizontalAlignment'	, 'center', 'enable', 'off', ...
                    'Units','normalized', 'Position', [0.5 0.5 0.4 0.1],'BackgroundColor', [1 1 1]);

                uicontrol(pp1,'style','text','string', 'Rout',...
                    'HorizontalAlignment'	, 'right', ...
                    'Units','normalized', 'Position', [0.05 0.33 0.4 0.1],'BackgroundColor', [1 1 1]);
                Rout_edit = uicontrol(pp1,'style','edit','enable','off',...
                    'HorizontalAlignment'	, 'center','Callback', @callRout_edit, ...
                    'Units','normalized', 'Position', [0.5 0.35 0.4 0.1],'BackgroundColor', [1 1 1]);

                PosFinder_btn = uicontrol(pp1,'Callback', @call_PosFinder_btn, 'String', 'Find Pos. for Cur. Image',...
                    'Units','normalized', 'Position', [0.1 0.1 0.8 0.15],'BackgroundColor', [1 1 1]);
                
                
               
                pos = app.takepos(pp2);
                start_btn = uicontrol(pp2,'Callback', @call_start, 'String', '', 'TooltipString', 'Start for PosFinder',...
                'Units','pixels', 'enable','on', 'BackgroundColor', [1 1 1],'Position', [pos(3)*0.5-pos(4)*0.4-pos(4)*0.05  pos(4)*0.45 pos(4)*0.4 pos(4)*0.4]);
                stop_btn = uicontrol(pp2,'Callback', @call_stop, 'String', '', 'TooltipString', 'Stop',...
                'Units','pixels','enable','on', 'BackgroundColor', [1 1 1],'Position', [ pos(3)*0.5+pos(4)*0.05  pos(4)*0.45 pos(4)*0.4 pos(4)*0.4]);
            
                msg = uicontrol(d,'style','text','string', 'Rout',...
                    'HorizontalAlignment'	, 'left', 'fontsize', 12,...
                    'Units','normalized', 'Position', [0 0 0.6 0.1],'BackgroundColor', [1 1 1]);
                btn = uicontrol(pp2, 'Callback', @ok , 'String','Close PosFinder',...
                    'Units','pixels', 'Position', [pos(3)/2-50 5 100 40],'BackgroundColor', [1 1 1]);

            end
            function init()
                set(sld, 'min', 1, 'max', get(app.sld1,'max'), 'Value', app.scrol_index,...
                'SliderStep', get(app.sld1,'SliderStep'), 'enable','on');
            
                set(m, 'AlphaDataMapping', 'direct');
                set(axx, 'ALimMode', 'manual');
                set(axx, 'ALim', [0, 255]);
                set(axx, 'YDir', 'reverse');
                set(axx, 'box', 'on');
                set(axx, 'DataAspectRatio', [1 1 1]);
                set(axx, 'PlotBoxAspectRatio', [1 1 1]);
                colormap(axx, gray(255));
                alphamap(axx, 'rampup', 255); 
                
                set(pll, 'xData', [], 'YData', []);
                set(prr, 'Position', [0 0 0 0]);
                
                set(CalcMethod_pop, 'value', app.Tracker.CalcMethod);
                set(th_edit, 'string',  app.Tracker.th);
                set(L_edit, 'string',  app.Tracker.RedArea);
                set(Rout_edit, 'string', app.Tracker.Rout);
                
                if app.Tracker.CalcMethod == 3 
                    set(Rout_edit, 'enable', 'on');
                else
                    set(Rout_edit, 'enable', 'off');
                end

                app.seticons(app.icons.start, start_btn);
                app.seticons(app.icons.stop, stop_btn);

                draw();
            end
            function draw()
                app.Tracker.takeim(app.scrol_index);

                set(pll, 'xData', [], 'YData', []);
                set(prr, 'Position', [0 0 0 0]);
                
                if app.Tracker.CalcMethod == 3 && app.Tracker.FramePos_l == 1
                    set(m, 'CData', app.Tracker.imFull + app.Tracker.FramePos.mask*50);
                else
                    set(m, 'CData', app.Tracker.imFull);
                end
                set(m, 'AlphaData', genAlphaData(0.5,app.Tracker.RedArea));
                set(axx, 'nextplot', 'add');
                set(prr, 'Position',[app.Tracker.RedArea, app.Tracker.RedArea, app.Tracker.CamSize(2)-2*app.Tracker.RedArea, app.Tracker.CamSize(1)-2*app.Tracker.RedArea],'EdgeColor','r');
                if app.Tracker.FramePos_l == 1
                    app.Tracker.FramePos_l = 0;
                    set(pll, 'XData', app.Tracker.FramePos.dCent(:,1), 'YData', app.Tracker.FramePos.dCent(:,2), 'Marker', '*', 'color', 'g','linestyle', 'none');
                else
                    if started == 1
                        set(pll, 'XData', app.Tracker.FramePos.dCent(:,1), 'YData', app.Tracker.FramePos.dCent(:,2), 'Marker', '*', 'color', 'r','linestyle', 'none');
                    elseif started == 2
                        if app.Tracker.checkHamData()
                            set(pll, 'XData', app.Tracker.HamData(app.scrol_index).Par(:,1), 'YData', app.Tracker.HamData(app.scrol_index).Par(:,2), 'Marker', '*', 'color', 'r','linestyle', 'none');
                        end
                     end
                    if started ~= 1
                        set(msg, 'string', [num2str(app.Tracker.FrameN(app.scrol_index)) '. Frame / ' num2str(app.Tracker.FrameN(length(app.Tracker.FrameN)))]);
                    end                
                end
                title(axx,'Image and Positions');
                set(axx, 'nextplot', 'replace');
            end
            function aData = genAlphaData(aV, L)
                aData = 255*ones(app.Tracker.CamSize(1), app.Tracker.CamSize(2));
                aData(1:L,:) = aV*aData(1:L,:);
                aData(L+1:end,1:L) = aV*aData(L+1:end,1:L);
                aData(L+1:end,end-L:end) = aV*aData(L+1:end,end-L:end);
                aData(end-L:end,L+1:end-L-1) = aV*aData(end-L:end,L+1:end-L-1);
            end
            function call_start(~,~)
                switch started
                    case {0,2}
                        objs = [CalcMethod_pop, L_edit, th_text, Rout_edit, PosFinder_btn, btn];
                        set(objs, 'enable', 'off');
                        app.seticons(app.icons.pause, start_btn);
                        set(start_btn, 'TooltipString', 'Pause for PosFinder');
                        started = 1;
                        app.Tracker.classdata = [];
                        app.Tracker.HamData = [];
                        app.Tracker.ParSay = [];
                        app.Tracker.Prepare;
                        app.renewform();
                        app.scrol_index = 0;
                        start(t);
                    case 1
                        started = 3;
                        app.seticons(app.icons.continue, start_btn);
                        set(start_btn, 'TooltipString', 'Continue for PosFinder');
                        stop(t);                        
                    case 2
                        
                    case 3
                        started = 1;
                        app.seticons(app.icons.pause, start_btn);
                        set(start_btn, 'TooltipString', 'Pause for PosFinder');
                        start(t);                       
                end
            end
            function call_stop(~,~)
                if started == 1 || started == 3
                    c = app.qBox(2, ['When you stop the process, you will lost all calculated data. Do you want to continue?']);
                    if ~isnan(c) && c == 1
                        started = 0;
                        stop(t);
                        app.Tracker.recalculation();
                        app.scrol_index = 1;
                        set(sld,'value',app.scrol_index);
                        app.seticons(app.icons.start, start_btn);
                        set(start_btn, 'TooltipString', 'Start for PosFinder');
                        objs = [CalcMethod_pop, L_edit, th_text, Rout_edit, PosFinder_btn, btn];
                        set(objs, 'enable', 'on');                        
                    end
                end
            end
            function stepProcess(~,~)
                stop(t);
                while started == 1
%                     disp(started);
                    if  app.scrol_index >= 0 && app.scrol_index <= length(app.Tracker.FrameN)-1
                        app.scrol_index = app.scrol_index + 1;
                        set(sld,'value',app.scrol_index);
                        app.Tracker.Calc(app.scrol_index);
                        set(msg, 'string', [num2str(app.scrol_index/length(app.Tracker.FrameN)*100) '%, Elapsed time is ' num2str(app.Tracker.FramePos.caltime)]);
                        draw();
                    else
                        started = 2;
                        stop(t);
                        app.seticons(app.icons.start, start_btn);
                        set(start_btn, 'TooltipString', 'Start for PosFinder');
                        set(app.sld1, 'enable', 'on');
                        app.Tracker.recalculation_l = 0;
                        app.Tracker.reclassification = 1;
                        set(msg, 'string', 'The calculation of the positions are completed!');
                        objs = [CalcMethod_pop, L_edit, th_text, Rout_edit, PosFinder_btn, btn];
                        set(objs, 'enable', 'on');
                    end
                end
            end
            function call_sld(~,~)
                aa = round( get(sld,'Value'));
                app.scrol_index = aa;
                draw();
            end
            function callCalcMethod(~,~)
                aa = get(CalcMethod_pop,'Value');
                app.Tracker.CalcMethod = aa;
                if app.Tracker.CalcMethod == 3 
                    if app.Tracker.tursay ~= 1
                        warning('It is possible for single specie particle.')
                        app.Tracker.Rout = 0;                
                    end
                    set(Rout_edit, 'enable', 'on');
                else
                    set(Rout_edit, 'enable', 'off');
                end
                draw();
            end
            function callL_edit(~,~)
                aa = get(L_edit,'String');
                aa = round(str2double(aa));
                if ~isnan(aa) && aa >= 0 && floor(aa*3) < floor(app.Tracker.CamSize(1)) && floor(aa*3) < floor(app.Tracker.CamSize(2))
                    app.Tracker.RedArea = aa;
                else
                    set(L_edit, 'string', app.Tracker.RedArea);
                end
                draw();
            end
            function callth_text(~,~)
                [th_, index_] = app.set_th(app.Tracker.th, sld, app.scrol_index);
                if ~isnan(th_) && ~isnan(index_)
                    app.scrol_index = index_;
                    app.Tracker.th = th_;
                    set(sld, 'value', app.scrol_index);
                    set(th_edit, 'string', app.Tracker.th);                    
                end
                draw();
            end
            function callRout_edit(~,~)
                aa=str2double(get(Rout_edit,'string'));
                if ~isnan(aa) && aa >= 0 && aa < 2000
                    app.Tracker.Rout = aa;
                else
                    set(Rout_edit,'string',num2str(app.Tracker.Rout))
                end
            end
            function call_PosFinder_btn(~,~)
                InterfaceObj=findobj(d,'Enable','on');
                set(InterfaceObj,'Enable','off');
                set(d, 'pointer', 'watch');
                pause(0.2)
                app.Tracker.Calc_Pos(app.scrol_index)
                app.Tracker.FramePos_l = 1;                    
                set(d, 'pointer', 'arrow');
                set(InterfaceObj,'Enable','on');
                draw();
            end            
            function ok(~,~)
%                 k = 1;
%                 if app.Tracker.checkHamData() == 1
%                     c = app.qBox(1, 'Calculated Positions are available. You must recalculate the positions. Do you want to continue?');
%                     if ~isnan(c) && c == 1
%                         k = 1;
%                         app.addMsg('ReCalculation of the positions is needed!');
%                         app.Tracker.recalculation_l = 1;
%                         app.Tracker.recalculation();
%                     else
%                         k = 0;
%                     end
%                 end
%                 if k == 1
%                     app.scrol_index = index;
%                     app.Tracker.CalcMethod = CalcMethod;
%                     app.Tracker.th = th;
%                     app.Tracker.Rout = Rout;
%                     app.Tracker.RedArea = RedArea;
%                     if app.Tracker.RedArea > app.Tracker.GreenArea
%                         app.Tracker.GreenArea = floor(app.Tracker.RedArea*1.2);
%                         if app.Tracker.GreenArea > app.Tracker.BlueArea
%                             app.Tracker.BlueArea = floor(app.Tracker.GreenArea*1.2);
%                         end                    
%                     end 
%                     app.Tracker.save_project_l = 0;
%                 end
                delete(d)
            end
        end
        function classyf(app)
            [d, t, axx, m, pll, rr, rg, rb, sld, msg, e, S_edit, G_checkbox, G_edit, B_checkbox, B_edit, tursay_pop, turpar_pop, fit_btn] = generateform();
            init();
%             inspect(e)
            uiwait(d);
            function [d, t, axx, m, pll, rr, rg, rb, sld, msg, e, S_edit, G_checkbox, G_edit, B_checkbox, B_edit, tursay_pop, turpar_pop, fit_btn] = generateform()
                pos = app.takepos(app.h);
                w = 600;
                he = 400;
                px = pos(1) + pos(3)/2-w/2;
                py = pos(2) + pos(4)/2-he/2;
                d = figure('Units','Pixels'...
                    ,'Position',[px py w he]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'Tracking and Classifing Properties'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'color', [1 1 1]);%
                
                t = timer('TimerFcn', @stepProcess, 'StartDelay', 0.2...
                ,'ExecutionMode', 'singleShot');
            
                pp0 = uipanel(d, 'Units','normalized','Position', [0.0 0.1 0.6 0.9],'title','Current Image', 'BackgroundColor', app.PanelBackgroundColor);
                pp1 = uipanel(d, 'Units','normalized','Position', [0.6 0.0 0.4 1.0],'title','Parameters', 'BackgroundColor', app.PanelBackgroundColor);
                
                axx = axes('parent', pp0, 'Position', [0.00 0.17 1 0.75]);
                m = image(axx);
                set(axx, 'nextplot', 'add');
                pll = plot(axx,0,0);
                rr = rectangle(axx, 'Position',[0 0 0 0]);
                rg = rectangle(axx, 'Position',[0 0 0 0]);
                rb = rectangle(axx, 'Position',[0 0 0 0]);
                set(axx, 'nextplot', 'replace');
                
                sld = uicontrol(pp0,'style','slider','callback', @call_sld, 'BackgroundColor', [1 1 1],...
                    'Units','normalized', 'Position', [0.00 0.03 1 0.05]);
                
                msg = uicontrol(d,'style','text','string', '',...
                    'HorizontalAlignment'	, 'left', 'fontsize', 12,...
                    'Units','normalized', 'Position', [0 0 0.6 0.1],'BackgroundColor', [1 1 1]);
                
                pos = app.takepos(pp1);
                btn = uicontrol(pp1, 'Callback', @ok , 'String','Track and Classfy',...
                    'Units','pixels', 'Position', [pos(3)/2-60 5 120 40],'BackgroundColor', [1 1 1]);

                uicontrol(pp1, 'style','text' , 'String', 'Tracking Parameters'...
                    ,'HorizontalAlignment', 'left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-40 pos(3) 20],'BackgroundColor', [1 1 1]); 
                uicontrol(pp1, 'style','text' , 'String', 'Max. Travel Length'...
                    ,'HorizontalAlignment', 'left',...
                    'Units','pixels', 'Position', [10 pos(4)-60 100 20],'BackgroundColor', [1 1 1]); 
                S_edit = uicontrol(pp1, 'style','edit','Callback', @call_S_edit , 'String', app.Tracker.StepLength,...
                    'Units','pixels', 'Position', [120 pos(4)-60 50 20]);
                
                
                    G_checkbox = uicontrol(pp1, 'style', 'checkbox', 'string', 'Allow New Labeling in Green Area',...
                        'HorizontalAlignment' , 'left', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-80 pos(3) 20], 'callback', @call_G_checkbox);
                    uicontrol(pp1, 'style', 'text', 'string', 'set Green Area Parameter',...
                        'HorizontalAlignment' , 'left', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-100 150 20]);
                    G_edit = uicontrol(pp1, 'style', 'edit', 'string', '','callback',@call_G_edit,...
                        'HorizontalAlignment' , 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [150 pos(4)-100 50 20]);

                    B_checkbox = uicontrol(pp1, 'style', 'checkbox', 'string', 'Allow New Labeling in Blue Area',...
                        'HorizontalAlignment' , 'left', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-120 pos(3) 20], 'callback', @call_B_checkbox);
                    uicontrol(pp1, 'style', 'text', 'string', 'set Blue Area Parameter',...
                        'HorizontalAlignment' , 'left', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-140 150 20]);
                    B_edit = uicontrol(pp1, 'style', 'edit', 'string', '','callback',@call_B_edit,...
                        'HorizontalAlignment' , 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [150 pos(4)-140 50 20]);

                uicontrol(pp1, 'style','text' , 'String', 'Classification Parameters'...
                    ,'HorizontalAlignment', 'left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-170 pos(3) 20],'BackgroundColor', [1 1 1]);
                
                    uicontrol(pp1,'style','text','string', 'Number of Specie',...
                        'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-190 100 20]);
                    tursay_pop = uicontrol(pp1,'style','popupmenu','Callback', @call_tursay,...
                        'String', {'1-One (R)', '2-Two (RG)', '3-Three (RGB)'},'enable','on',...
                        'Units','pixels', 'Position', [120 pos(4)-190 100 20]);

                    uicontrol(pp1,'style','text','string', 'Sorting Parameter','fontsize', 8,...
                        'HorizontalAlignment'	, 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-220 100 20]);
                    turpar_pop = uicontrol(pp1,'style','popupmenu','Callback', @call_turpar,...
                        'String', {'0-None', '1-tA-Area', '2-tI-Intensity'},'enable','on',...
                        'Units','pixels', 'Position', [120 pos(4)-220 100 20]);
                    
                 fit_btn = uicontrol(pp1, 'Callback', @call_fit_btn , 'String','see Distributions',...
                    'Units','pixels', 'Position', [pos(3)/2-50 pos(4)-260 100 30],'BackgroundColor', [1 1 1]);
                
%                     uicontrol(pp1,'style','text','string', 'Peak Bounds',...
%                         'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1], ...
%                         'Units','pixels', 'Position', [0 pos(4)-290 pos(3) 20]);  
                    
                e = uitable(pp1);
                set(e,'ColumnName',{'Left Bound'; 'Right Bound'},...
                    'RowName',{'1th';'2th';'3th'},...
                    'ColumnEditable',[false false],...
                    'ColumnFormat',({[] []}),...
                    'ColumnWidth', {70 70},...%'auto'
                    'Position',[20 pos(4)-345 pos(3)-40 78]);
                
                
%                     ww = 50;
%                     px = pos(3)/2-ww;
%                     py = 90;                    'CellEditCallback ', @call_e,...
% 
%                     for i = 1 : 6
%                         a = ceil(i/2);
%                         b = mod(i, 2);
%                         if b == 0
%                             b = 2;
%                         end
%                         e(i) = uicontrol(pp1,'style','edit','string', app.Tracker.limits(a, b),'userdata',[a, b],...
%                             'HorizontalAlignment'	, 'center', 'BackgroundColor', [1 1 1], ...
%                             'Units','pixels', 'Position', [(b-1)*ww+px 4-(a-1)*20+py ww 20],'Callback', @call_e);
%                     end
                    

                
                
                
                
            end
            function init()
                set(sld, 'min', 1, 'max', get(app.sld1,'max'), 'Value', app.scrol_index,...
                'SliderStep', get(app.sld1,'SliderStep'), 'enable','on');
            
                set(tursay_pop, 'value', app.Tracker.tursay);
                set(turpar_pop, 'value', app.Tracker.turpar+1);
            
                set(m, 'AlphaDataMapping', 'direct');
                set(axx, 'ALimMode', 'manual');
                set(axx, 'ALim', [0, 255]);
                set(axx, 'YDir', 'reverse');
                set(axx, 'box', 'on');
                set(axx, 'DataAspectRatio', [1 1 1]);
                set(axx, 'PlotBoxAspectRatio', [1 1 1]);
                colormap(axx, gray(255));
                alphamap(axx, 'rampup', 255); 
                
                set(pll, 'xData', [], 'YData', []);
                set(rr, 'Position', [0 0 0 0]);
                set(rg, 'Position', [0 0 0 0]);
                set(rb, 'Position', [0 0 0 0]);
                
                
                set(S_edit, 'string', app.Tracker.StepLength);
                set(G_checkbox, 'value', app.Tracker.AllowNewLabelGreen);
                set(B_checkbox, 'value', app.Tracker.AllowNewLabelBlue);
                set(G_edit,'string', app.Tracker.GreenArea);
                set(B_edit,'string', app.Tracker.BlueArea);
                
                set(e,'Data',app.Tracker.limits);
                
%                 for i = 1 : 6
%                     a = ceil(i/2);
%                     b = mod(i, 2);
%                     if b == 0
%                         b = 2;
%                     end
%                     set(e(i), 'string', app.Tracker.limits(a, b));
%                 end
                draw();
            end
            function draw()
                app.Tracker.takeim(app.scrol_index);

                set(pll, 'xData', [], 'YData', []);
                set(rr, 'Position', [0 0 0 0]);
                set(rg, 'Position', [0 0 0 0]);
                set(rb, 'Position', [0 0 0 0]);
                
                set(m, 'CData', app.Tracker.imFull);

                set(m, 'AlphaData', genAlphaData(0.5,app.Tracker.RedArea));
                set(axx, 'nextplot', 'add');
                set(rr, 'Position',[app.Tracker.RedArea, app.Tracker.RedArea, app.Tracker.CamSize(2)-2*app.Tracker.RedArea, app.Tracker.CamSize(1)-2*app.Tracker.RedArea],'EdgeColor','r');
                if app.Tracker.AllowNewLabelGreen == 1
                    set(rg, 'Position',[app.Tracker.GreenArea, app.Tracker.GreenArea, app.Tracker.CamSize(2)-2*app.Tracker.GreenArea, app.Tracker.CamSize(1)-2*app.Tracker.GreenArea],'EdgeColor','g');
                end
                if app.Tracker.AllowNewLabelBlue == 0
                    set(rb, 'Position',[app.Tracker.BlueArea, app.Tracker.BlueArea, app.Tracker.CamSize(2)-2*app.Tracker.BlueArea, app.Tracker.CamSize(1)-2*app.Tracker.BlueArea],'EdgeColor','b');
                end
                
                title(axx,'Image and Positions');
                set(axx, 'nextplot', 'replace');
                
                set(e,'enable', 'off');
%                 for j = 1 : length(e)
% %                     set(e(j),'enable', 'off');
%                 end
%                 if app.Tracker.turpar > 0
%                     for j = 1 : app.Tracker.tursay
% %                         set(e(j*2 - 1),'enable', 'on');
% %                         set(e(j*2),'enable', 'on');
%                     end 
%                 end

            end
            function aData = genAlphaData(aV, L)
                aData = 255*ones(app.Tracker.CamSize(1), app.Tracker.CamSize(2));
                aData(1:L,:) = aV*aData(1:L,:);
                aData(L+1:end,1:L) = aV*aData(L+1:end,1:L);
                aData(L+1:end,end-L:end) = aV*aData(L+1:end,end-L:end);
                aData(end-L:end,L+1:end-L-1) = aV*aData(end-L:end,L+1:end-L-1);
            end
            function call_sld(~,~)
                aa = round( get(sld,'Value'));
                app.scrol_index = aa;
                draw();
            end
            function ok(~,~)
                start(t);
%                 delete(d);
            end
            function call_turpar(~, ~)
                aa = get(turpar_pop, 'value') - 1;
                if aa == 0
                    app.Tracker.turpar = 0;
                else
                    app.Tracker.turpar = aa;
                    app.Tracker.distributions();
                end
                app.Tracker.save_project_l = 0;
                draw();
            end
            function call_tursay(~,~)
                app.Tracker.tursay = get(tursay_pop,'value');
                app.Tracker.save_project_l = 0;
                draw();
            end
            function call_G_checkbox(~, ~)
                aa = get(G_checkbox, 'value');
                if aa == 1
                    app.Tracker.AllowNewLabelGreen = 1;
                else
                    app.Tracker.AllowNewLabelGreen = 0;
                end
                app.Tracker.save_project_l = 0;
                draw();
            end
            function call_B_checkbox(~, ~)
                aa = get(B_checkbox, 'value');
                if aa == 1
                    app.Tracker.AllowNewLabelBlue = 1;
                else
                    app.Tracker.AllowNewLabelBlue = 0;
                end
                app.Tracker.save_project_l = 0;
                draw();
            end
            function call_S_edit(~, ~)
                aa = get(S_edit, 'string');
                aa = round(str2double(aa));
                if app.Tracker.CamSize(1) <= app.Tracker.CamSize(2)
                    max_v = floor(app.Tracker.CamSize(1)/2);
                else
                    max_v = floor(app.Tracker.CamSize(2)/2);
                end
                if ~isnan(aa) && aa >= 1 && aa <= max_v
                    app.Tracker.StepLength = floor(aa);
                    app.Tracker.save_project_l = 0;
                else
                    set(S_edit, 'string', app.Tracker.StepLength);
                end 
                draw();
            end
            function call_G_edit(~, ~)
                aa = get(G_edit, 'string');
                aa = round(str2double(aa));
                if app.Tracker.CamSize(1) <= app.Tracker.CamSize(2)
                    max_v = floor(app.Tracker.CamSize(1)/3);
                else
                    max_v = floor(app.Tracker.CamSize(2)/3);
                end
                if ~isnan(aa) && aa >= app.Tracker.RedArea && aa <= max_v
                    app.Tracker.GreenArea = floor(aa);
                    if app.Tracker.GreenArea > app.Tracker.BlueArea
                        app.Tracker.BlueArea = floor(app.Tracker.GreenArea*1.2);
                        set(B_edit, 'string', app.Tracker.BlueArea);
                    end
                    app.Tracker.save_project_l = 0;
                else
                    set(G_edit, 'string', app.Tracker.GreenArea);
                end
                draw();
            end
            function call_B_edit(~, ~)
                aa = get(B_edit, 'string');
                aa = round(str2double(aa));
                if app.Tracker.CamSize(1) <= app.Tracker.CamSize(2)
                    max_v = floor(app.Tracker.CamSize(1)/3);
                else
                    max_v = floor(app.Tracker.CamSize(2)/3);
                end
                if ~isnan(aa) && aa >= app.Tracker.GreenArea && aa <= max_v
                    app.Tracker.BlueArea = floor(aa);
                    app.Tracker.save_project_l = 0;
                else
                    set(B_edit, 'string', app.Tracker.BlueArea);
                end
                draw();
            end
            function call_fit_btn(~,~)
                app.distributions();
                set(tursay_pop, 'value', app.Tracker.tursay);
                set(turpar_pop, 'value', app.Tracker.turpar+1);
                set(e,'Data',app.Tracker.limits);
%                 for i = 1 : 3
%                     set(e((i-1)*2+1),'string', app.Tracker.limits(i,1));
%                     set(e(i*2),'string', app.Tracker.limits(i,2));
%                 end
                draw();
            end
            function stepProcess(~,~)
                objs = findobj(d, 'enable', 'on');
                set(objs, 'enable', 'off');
                set(msg, 'enable', 'on');
                set(d, 'pointer', 'watch');
                pause(0.4);
%                 app.Tracker.Classify();
                app.Tracker.classdata = [];
                i = 0;
                while i < length(app.Tracker.FrameN)
                    i = i + 1;
                    set(msg, 'string', [num2str(i) 'th Frame, ' num2str(i/length(app.Tracker.FrameN)*100) '%']);
                    pause(0.0002);
                    app.Tracker.TimeSeries(i);
                end
                set(msg, 'string', 'Tracking and Classification are completed!');
                app.Tracker.reclassification = 0;
%                 app.createPops();
%                 app.renewform();
                set(d, 'pointer', 'arrow');
                delete(d);
            end
            
        end
        function distributions(app)
            [d, axx, m, pll, tursay_pop, turpar_pop, fit_btn, e] = generateform();
            init();
%             print(gcf,'test.eps','-depsc2');
            uiwait(d);
            function [d, axx, m, pll, tursay_pop, turpar_pop, fit_btn, e] = generateform()
                pos = app.takepos(app.h);
                w = 600;
                he = 400;
                px = pos(1) + pos(3)/2-w/2;
                py = pos(2) + pos(4)/2-he/2;
                d = figure('Units','Pixels'...
                    ,'Position',[px py w he]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'Distributions'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'color', [1 1 1]);%
            
                pp0 = uipanel(d, 'Units','normalized','Position', [0.0 0.0 0.6 1],'title','Distribution', 'BackgroundColor', app.PanelBackgroundColor);
                pp1 = uipanel(d, 'Units','normalized','Position', [0.6 0.0 0.4 1],'title','Parameters', 'BackgroundColor', app.PanelBackgroundColor);
                
                axx = axes('parent', pp0, 'Position', [0.1 0.1 0.8 0.8]);
                m = image(axx);
                pll = plot(axx,0,0);
                
                pos = app.takepos(pp1);
                
                btn = uicontrol(pp1, 'Callback', @ok , 'String','Use The Limits',...
                    'Units','pixels', 'Position', [pos(3)/2-50 20 100 40],'BackgroundColor', [1 1 1]);

                uicontrol(pp1, 'style','text' , 'String', 'Classification Parameters'...
                    ,'HorizontalAlignment', 'left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-40 pos(3) 20],'BackgroundColor', [1 1 1]);
                
                    uicontrol(pp1,'style','text','string', 'Number of Specie',...
                        'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-70 100 20]);
                    tursay_pop = uicontrol(pp1,'style','popupmenu','Callback', @call_tursay,...
                        'String', {'1-One (R)', '2-Two (RG)', '3-Three (RGB)'},'enable','on',...
                        'Units','pixels', 'Position', [120 pos(4)-70 100 20]);

                    uicontrol(pp1,'style','text','string', 'Sorting Parameter','fontsize', 8,...
                        'HorizontalAlignment'	, 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [10 pos(4)-100 100 20]);
                    turpar_pop = uicontrol(pp1,'style','popupmenu','Callback', @call_turpar,...
                        'String', {'0-None', '1-tA-Area', '2-tI-Intensity'},'enable','on',...
                        'Units','pixels', 'Position', [120 pos(4)-100 100 20]);
                    
                 fit_btn = uicontrol(pp1, 'Callback', @fitt , 'String','see Distributions',...
                    'Units','pixels', 'Position', [pos(3)/2-50 pos(4)-150 100 30],'BackgroundColor', [1 1 1]);   
                
                    ww = pos(3)/2;
                    px = pos(3)/2-ww;
                    py = 160;
                    uicontrol(pp1,'style','text','string', 'Peak Bounds',...
                        'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [0 pos(4)-200 pos(3) 20]);
                    
                    uicontrol(pp1,'style','text','string', 'Left Bounds',...
                        'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [0 pos(4)-220 pos(3)/2 20]);
                    uicontrol(pp1,'style','text','string', 'Right Bounds',...
                        'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1], ...
                        'Units','pixels', 'Position', [pos(3)/2 pos(4)-220 pos(3)/2 20]);
                    
                    for i = 1 : 6
                        a = ceil(i/2);
                        b = mod(i, 2);
                        if b == 0
                            b = 2;
                        end
                        e(i) = uicontrol(pp1,'style','edit','string', app.Tracker.limits(a, b),'userdata',[a, b],...
                            'HorizontalAlignment'	, 'center', 'BackgroundColor', [1 1 1], ...
                            'Units','pixels', 'Position', [(b-1)*ww+px 4-(a-1)*20+py ww 20],'Callback', @call_e);
                    end
                    
                    set(e(1),'foregroundcolor', 'r');
                    set(e(2),'foregroundcolor', 'r');
                    set(e(3),'foregroundcolor', 'g');
                    set(e(4),'foregroundcolor', 'g');
                    set(e(5),'foregroundcolor', 'b');
                    set(e(6),'foregroundcolor', 'b');
                
            end
            function init()
                set(tursay_pop, 'value', app.Tracker.tursay);
                set(turpar_pop, 'value', app.Tracker.turpar+1);
                draw();
            end
            function ok(~,~)
                delete(d);
            end
            function draw()
                if app.Tracker.checkHamData() == 1
                    set(fit_btn, 'String', ['Fit to ' num2str(get(tursay_pop,'value')) ' Gaussian']);
                    for j = 1 : length(e)
                        set(e(j),'enable', 'off');
                    end
                    if app.Tracker.turpar > 0
                        set(fit_btn,'enable','on')
                        for j = 1 : app.Tracker.tursay
                            set(e(j*2 - 1),'enable', 'on');
                            set(e(j*2),'enable', 'on');
                        end  
                        if  app.Tracker.datatur > 0
                            plot(axx, app.Tracker.centers, app.Tracker.nelements,'*b')
                            hold on
                            if app.Tracker.fit_l ==  1
                                plot(axx, app.Tracker.fitt(:,1), app.Tracker.fitt(:,2),'-r')
                            end
                        else

                        end
                        y = get(axx, 'YLim');
                        y = y(1,2)*0.75;
                        for i = 1 : app.Tracker.tursay
                            plot(axx, app.Tracker.limits(i,1)*ones(1,length(0:y)),0:y,'-','color',app.Tracker.coll(i,:))
                            hold on
                            plot(axx,app.Tracker.limits(i,2)*ones(1,length(0:y)),0:y,'-','color',app.Tracker.coll(i,:))
                            text(axx,app.Tracker.limits(i,1),y/2,num2str(app.Tracker.limits(i,1)),'color',app.Tracker.coll(i,:))
                            text(axx,app.Tracker.limits(i,2),y/3,num2str(app.Tracker.limits(i,2)),'color',app.Tracker.coll(i,:))                
                        end
                        hold off
                        title(axx, 'Distributions and Limits')
                    else
                        set(fit_btn,'enable','off')  
                        image(app.icons.logo);
                        axis equal
                        axis off
                    end
                else
                    set(fit_btn,'enable','off')  
                    m = image(aaa);
                    set(m, 'CData', app.icons.logo);
                    axis equal
                    axis off
                end

            end
            function call_turpar(~, ~)
                aa = get(turpar_pop, 'value') - 1;
                if aa == 0
                    app.Tracker.turpar = 0;
                else
                    app.Tracker.turpar = aa;
                    app.Tracker.distributions();
                end
                app.Tracker.save_project_l = 0;
                draw();
            end
            function call_tursay(~,~)
                app.Tracker.tursay = get(tursay_pop,'value');
                app.Tracker.save_project_l = 0;
                draw();
            end
            function call_e(s, ~)
                aa = get(s,'string');
                aa = str2double(aa);
                int = get(s,'userdata');
                if ~isnan(aa)
                    app.Tracker.limits(int(1) , int(2)) = aa;
                    app.Tracker.save_project_l = 0;
                else
                    set(s,'string', app.Tracker.limits(int(1) , int(2)));
                end
                draw();
%                 print(cgf,'dist_eps','-depsc2')
            end
            function fitt(~,~)
                app.Tracker.FitLimits();
                for i = 1 : 3
                    set(e((i-1)*2+1),'string', app.Tracker.limits(i,1));
                    set(e(i*2),'string', app.Tracker.limits(i,2));
                end
                app.Tracker.save_project_l = 0;
                draw();
            end
        end
        function aboutGUI(app)
            [d, m] = generateForm();
            init();
            uiwait(d);
            function [d, m] = generateForm()
                pos = app.takepos(app.h);
                px = pos(1) + pos(3)/2-300/2;
                py = pos(2) + pos(4)/2-150/2;
                d = figure('Units','pixels'...
                    ,'Position',[px py 300 150]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'About...'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'color', [1 1 1]);%

                m = uicontrol(d,'style','checkbox','enable', 'inactive',...
                    'BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [5 25 100 100]);
                
                p = uipanel(d, 'Title', 'mPosTracker','Units','pixels','Position', [110 65 180 75] ,'BackgroundColor', [1 1 1]);
                
                uicontrol(p,'style','text','string', 'Multiple Position Tracker',...
                    'HorizontalAlignment'	, 'center','BackgroundColor', [1 1 1],...
                    'Units','char', 'Position', [0 3 35 1]);
                uicontrol(p,'style','text','string', 'This is a project',...
                    'HorizontalAlignment'	, 'center','BackgroundColor', [1 1 1],...
                    'Units','char', 'Position', [0 2 35 1]);
                uicontrol(p,'style','text','string', 'Copy - Right 2021',...
                    'HorizontalAlignment'	, 'center','BackgroundColor', [1 1 1],...
                    'Units','char', 'Position', [0 1 35 1]);


                uicontrol(d, 'Callback', @ok , 'String','Ok','fontsize', 9,...
                    'Units','pixels', 'Position', [150 15 100 40]);%,'BackgroundColor', [1 1 1]

            end
            function init()
                app.seticons(app.icons.icon, m);
            end
            function ok(~,~)
                delete(d);
            end
        end
        function helpGUI(app)
            [d, m] = generateForm();
            init();
            uiwait(d);
            function [d, m] = generateForm()
                pos = app.takepos(app.h);
                px = pos(1) + pos(3)/2-300/2;
                py = pos(2) + pos(4)/2-150/2;
                d = figure('Units','pixels'...
                    ,'Position',[px py 300 150]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'Help...'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'color', [1 1 1]);%

                m = uicontrol(d,'style','checkbox','enable', 'inactive',...
                    'BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [5 25 100 100]);
                
                p = uipanel(d, 'Title', 'mPosTracker','Units','pixels','Position', [110 65 180 75] ,'BackgroundColor', [1 1 1]);
                
                uicontrol(p,'style','text','string', 'Will be!!!',...
                    'HorizontalAlignment'	, 'center','BackgroundColor', [1 1 1],...
                    'Units','char', 'Position', [0 3 35 1]);

                uicontrol(d, 'Callback', @ok , 'String','Ok',...
                    'Units','pixels', 'Position', [150 15 100 40]);%,'BackgroundColor', [1 1 1]

            end
            function init()
                app.seticons(app.icons.help, m);
            end
            function ok(~,~)
                delete(d);
            end
        end
        function tableGUI(app)
            Exfilename = '';
            [d, tHead, table] = generateForm();
            init();
            uiwait(d);
            function [d, tHead, table] = generateForm()
                pos = app.takepos(app.h);
                px = pos(1) + pos(3)/2-400/2;
                py = pos(2) + pos(4)/2-400/2;
                d = figure('Units','pixels'...
                    ,'Position',[px py 400 400]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'see Trajectories as a Table...'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'color', [1 1 1]);%

                
                
                tHead = uicontrol(d,'style','text','string', 'Particle Label','enable','on','fontsize',12,...
                        'HorizontalAlignment','center','Units','normalized', 'Position', [0 0.95 1 0.05]);
                table = uitable(d, 'data', [],'Units','normalized','position', [0 0.1 1 0.85], 'enable', 'on');
                
                uicontrol(d, 'Callback', @extract , 'String','Extract to File (txt or xls)',...
                    'Units','normalized', 'Position', [0.1 0.01 0.5 0.08]);%,'BackgroundColor', [1 1 1]
                
                uicontrol(d, 'Callback', @ok , 'String','Close',...
                    'Units','normalized', 'Position', [0.7 0.01 0.2 0.08]);%,'BackgroundColor', [1 1 1]

            end
            function init()
                pos = get(app.SelectedObj, 'userdata');
                x = app.Tracker.ClassDataMic(pos(1)).Par(pos(2)).Data;
                v = app.Tracker.CalcVelocity(x);
                
                Exfilename = [ num2str(pos(1)) 'th_kind_'  num2str(pos(2)) 'th_Particle'];
                set(tHead, 'string', Exfilename);
                
                set(table, 'ColumnName', {'Time (ms)','X (mic)','Y (mic)','A (mic^2)', 'Average Displacement', 'Last Displacement' ,'Average Velocity', 'Instantaneous Velocity'});
                dd = [x,v];
                set(table, 'data', dd);
            end
            function extract(~,~)
                x = get(table, 'data');
                if ~isempty(d)
                    if app.Tracker.vid_filename(length(app.Tracker.vid_filename)-3) == '.'
                        file = app.Tracker.vid_filename(1:length(app.Tracker.vid_filename)-4);
                    else
                        file = app.Tracker.vid_filename;
                    end
                    file = [file '_avi_' Exfilename '.xls'];
                    [file, path, FilterIndex] = uiputfile({'*.xls'; '*.txt'; '*.mat'},'Save Data as a .xls file',file);

                    if path ~= 0 %&& file ~= 0
                        switch FilterIndex
                            case 1
                                xlswrite([path file], x);
                            case 2
                                fid=fopen([path file],'w');
                                fprintf(fid, 'Time X(pixel) Y(pixel) A (pixel^2) A.Displacement L.Displacement A.Velocity I.Velocity\r\n');
                                fprintf(fid, '%5.3f %5.3f %5.3f %5.3f %5.3f %5.3f %5.3f %5.3f \r\n', x');
                                fclose(fid);
                            case 3
                                save([path file], 'x','-mat');
                        end
                    else
                    end
                end
            end
            function ok(~,~)
                delete(d);
            end
        end
        function det_inArea(app)
            
            ss = app.Tracker.CamSize;
            mvec = zeros(1,2);
            selectedVec1 = zeros(1,2);
            selectedVec2 = zeros(1,2);
            save_rect12 = zeros(1,2);
            click = zeros(1,1);
            rect = zeros(1,4);
            RefMod = uint8(1);
            cent = zeros(1,2);
            
            if ~isempty(app.inArea)
                rect = app.inArea;
            else
                rect(1) = 1;
                rect(2) = 1;
                rect(3) = ss(2);
                rect(4) = ss(1);
            end
            
            if rect(3) < ss(2) && rect(4) < ss(1)
                click = 2;
            end

            [d, axx, xe, ye, we, he, r1, r2, sld] = generateForm();
            
            setsld();
            set(sld, 'value', app.scrol_index);
            draw();

            uiwait(d);
            function [d, axx, xe, ye, we, he, r1, r2, sld] = generateForm()
                pos = app.takepos(app.h);
                w = 600;
                he = 400;
                px = pos(1) + pos(3)/2-w/2;
                py = pos(2) + pos(4)/2-he/2;
                d = figure('Units','pixels'...
                    ,'Position',[px py w he]...
                    ,'toolbar', 'none'...
                    ,'menubar', 'none'...
                    ,'name', 'Determine the Interesting Area'...
                    ,'visible','on'...
                    ,'WindowStyle','modal'...
                    ,'NumberTitle','off'...
                    ,'Resize', 'off'...
                    ,'WindowButtonMotionFcn', @mouseMove...
                    ,'WindowButtonDownFcn', @mouseClick...
                    ,'WindowButtonUpFcn', @mouseUpClick,'color', app.WinBackgroundColor);%
                
                pp0 = uipanel(d, 'Units','normalized','Position', [0.0 0.0 0.6 1.0],'title','Image', 'BackgroundColor', app.PanelBackgroundColor);
                pp1 = uipanel(d, 'Units','normalized','Position', [0.6 0.0 0.4 1.0],'title','Area Parameters', 'BackgroundColor', app.PanelBackgroundColor);
                
                axx = axes('parent', pp0, 'Units','normalized', 'Position', [0.00 0.17 1 0.75]);
                sld = uicontrol(pp0,'style','slider','callback', @call_sld, 'BackgroundColor', [1 1 1],...
                    'Units','normalized', 'Position', [0.00 0.03 1 0.05], 'enable','off');
                
                pos = app.takepos(pp1);

                uicontrol(pp1, 'style','text' , 'String', 'Interesting Area','HorizontalAlignment', 'Left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-60 100 20],'BackgroundColor', [1 1 1]);
               
                xt = uicontrol(pp1, 'style','text' , 'String', 'X :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-80 20 20],'BackgroundColor', [1 1 1]);
                yt = uicontrol(pp1, 'style','text' , 'String','Y :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10 pos(4)-100 20 20],'BackgroundColor', [1 1 1]);
                wt = uicontrol(pp1, 'style','text' , 'String','Width :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10+80 pos(4)-80 40 20],'BackgroundColor', [1 1 1]);
                ht = uicontrol(pp1, 'style','text' , 'String','Height :','HorizontalAlignment', 'Left',...
                    'Units','pixels', 'Position', [10+80 pos(4)-100 40 20],'BackgroundColor', [1 1 1]);
                
                xe = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(1)),...
                    'Units','pixels', 'Position', [30 pos(4)-80 50 20]);
                ye = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(2)),...
                    'Units','pixels', 'Position', [30 pos(4)-100 50 20]);
                we = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(3)),...
                    'Units','pixels', 'Position', [130 pos(4)-80 50 20]);
                he = uicontrol(pp1, 'style','edit','Callback', @enter , 'String',num2str(rect(4)),...
                    'Units','pixels', 'Position', [130 pos(4)-100 50 20]);
                

                uicontrol(pp1, 'style','text' , 'String', 'Reference Point For Area Center','HorizontalAlignment', 'Left','FontWeight', 'bold',...
                    'Units','pixels', 'Position', [10 pos(4)-125 pos(3) 20],'BackgroundColor', [1 1 1]);
                r1 = uicontrol(pp1, 'style', 'radiobutton' , 'String', 'at corner', 'value', 1,'BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [30 pos(4)-140 70 20], 'callback', @rbutton1);        
                r2 = uicontrol(pp1, 'style', 'radiobutton' , 'String', 'at center','BackgroundColor', [1 1 1],...
                    'Units','pixels', 'Position', [120 pos(4)-140 70 20], 'callback', @rbutton2);    
          
            
                uicontrol(pp1, 'Callback', @ok , 'String','set interesting area',...
                'Units','pixels', 'Position', [pos(3)/2-75 10 150 40],'BackgroundColor', app.WinBackgroundColor);
              
            end
            function call_sld(s,e)
                aa = round( get(sld,'Value'));
                app.scrol_index = aa;
                draw();
            end
            function setsld()
                set(sld, 'min', 1, 'max', length(app.Tracker.FrameN), 'Value', 1,...
                'SliderStep',[1/length(app.Tracker.FrameN), 10/length(app.Tracker.FrameN)], 'enable','on');
            end
            function mouseMove(s,e)
                mvec = getPoint();
                switch click 
                    case 0
                        if insideRect(mvec, [1, 1, ss(2), ss(1)])
                            set(d,'Pointer','cross');
                        else
                            set(d,'Pointer','arrow');
                        end
                    case 1
                        selectedVec2 = mvec;
                        draw();
                    case 2
                        if insideRect(mvec, rect)
                            set(d,'Pointer','fleur');
                        else
                            set(d,'Pointer','arrow');
                        end
                    case 3
                        selectedVec2 = mvec;
                        draw();
                end

            end
            function mouseClick(s,e)
                mvec = getPoint();
                switch click 
                    case 0
                        selectedVec1 = mvec;
                        click = 1;                
                    case 1

                    case 2
                        if insideRect(mvec, rect) == 1
                            selectedVec1 = mvec;
                            save_rect12 = rect(1:2);
                            click = 3;
                        else
                            if insideRect(mvec, [1, 1 , ss(2), ss(1)])
                                click = 0;
                                rect = zeros(1,4);
                                draw();                        
                            end
                        end
                    case 3

                end

            end
            function t = insideRect(v, area)
                t = 0;
                if v(1) > area(1) && v(1) < area(1) + area(3) - 1
                    if v(2) > area(2) && v(2) < area(2) + area(4) - 1
                        t = 1;
                    end
                end

            end
            function mouseUpClick(~,~)
                mvec = getPoint();
                switch click 
                    case 0

                    case 1
                        click = 2;
                    case 2

                    case 3
                        click = 2;

                end
            end
            function draw()
                app.Tracker.takeim( app.scrol_index);%takeimage(index);%buraya bakkkk!!!!!!!!!!!!!
                
                image(app.Tracker.imFull);
                
                colormap(gray(255));
                if click == 1
                    rect = calcRect();
                end
                if click == 3
                    rect = translation();
                end

                rect = floor(rect);
                if RefMod == 1
                    cent = rect(1:2);
                else
                    cent = [rect(1)+(rect(3)/2), rect(2) + (rect(4)/2)];
                end
                
                hold on
                if click == 0
                    rectangle('Position',rect,'EdgeColor','r')
                else
%                     plotv(cent' ,'-y'),'LineStyle','--'
                    line([0 cent(1)],[0 cent(2)],'Color','y')
                    rectangle('Position',rect,'EdgeColor','y')
                    plot(cent(1), cent(2), 'oy')
                    plot(cent(1), cent(2), '.y')
                end
 
                if app.Tracker.checkHamData()
                    if app.Tracker.checkClassData()
                        for k = 1 : app.Tracker.tursay
                            data = [];
                            for k2 = 1 : numel(app.Tracker.classdata(k).Par)
                                x = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,2);
                                y = app.Tracker.classdata(k).Par(k2).Data(app.scrol_index,3);
                                data = [data; x, y];
                            end
                            plot(data(:,1), data(:,2), 'color', app.Tracker.coll(k,:), 'Marker', '*', 'LineStyle', 'none');
                        end
                    else
                        plot(app.Tracker.HamData(app.scrol_index).Par(:,1), app.Tracker.HamData(app.scrol_index).Par(:,2), 'Marker', '*', 'color', 'r', 'LineStyle', 'none');
                    end
                end

                hold off
                axis equal
                
                set(xe, 'string', cent(1));
                set(ye, 'string', cent(2));
                set(we, 'string', rect(3));
                set(he, 'string', rect(4));
                
            end
            function r = translation()
                vec = selectedVec2 - selectedVec1;
                sPoint = save_rect12(1:2) + vec;
                if abs(sPoint(1)) + rect(3) < ss(2) && abs(sPoint(2)) + rect(4) < ss(1) ...
                        && sPoint(1) > 0 && sPoint(2) > 0
                    r = [sPoint(1), sPoint(2), rect(3), rect(4)];
                else
                    r = rect;
                end

            end
            function r = calcRect()
                vec = selectedVec2 - selectedVec1;
                if abs(selectedVec2(1)) < ss(2) && abs(selectedVec2(2)) < ss(1) ...
                        && selectedVec2(1) > 0 && selectedVec2(2) > 0
                    if vec(1) < 0
                        if vec(2) < 0
                            sPoint = selectedVec2;
                        else 
                            sPoint = selectedVec1 + [vec(1), 0];
                        end
                    else
                        if vec(2) < 0
                            sPoint = selectedVec1 + [0, vec(2)];
                        else 
                            sPoint = selectedVec1;
                        end
                    end
                    r = [sPoint(1), sPoint(2), abs(vec(1)), abs(vec(2))];
                else
                    r = rect;
                end

            end
            function enter(~, ~)
                x = round(str2double(get(xe,'string')));
                y = round(str2double(get(ye,'string')));
                w = round(str2double(get(we,'string')));
                h_= round(str2double(get(he,'string')));
                if ~isnan(x) && ~isnan(y) && ~isnan(w) && ~isnan(h_)
                    if RefMod == 1
                      if x > 0 && x + w - 1 <= ss(2) && w > 0 && h_>0 ...
                            && y > 0 && y + h_ -1 <=ss(1) && w<=ss(2) && h_<=ss(1)
                        rect(1) = x;
                        rect(2) = y;
                        rect(3) = w;
                        rect(4) = h_;
                      end              
                    else
                      if x - w/2 > 0 && x + w/2 <= ss(2) && w > 0 && h_>0 ...
                            && y - h_/2 > 0 && y + h_/2 <= ss(1) && w <= ss(2) && h_ <= ss(1)
                        rect(1) = x - w/2;
                        rect(2) = y - h_/2;
                        rect(3) = w;
                        rect(4) = h_;
                      end    
                    end

                end
                draw();
            end
            function c = getPoint()
                c = get (axx, 'CurrentPoint');
                c = [c(1,1), c(1,2)];
            end
            function ok(~,~)
                app.inArea = rect;
                delete(d);
            end
            function rbutton1(s,~)
                set(r1, 'value', 1);
                set(r2, 'value', 0);
                RefMod = 1;
                draw();
            end
            function rbutton2(s,~)
                set(r1, 'value', 0);
                set(r2, 'value', 1);
                RefMod = 2;
                draw();
            end
        end
    end
end

% make the folder of this file to the current folder of Matlab