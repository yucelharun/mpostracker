% This code is written by Harun, 2021
classdef PosFinder
    properties
        imFull = 0; %The image under consideration
        th = 128; %Therahold value
        L = 20; %Red Area Parameter, Ignoring side of border of the image
        CamSize = 0; %Image size
        X = 0; % X coordinates of the image
        Y= 0; % Y coordinates of the image
        dx = 0; %x component of image gradient vector
        dy = 0; %y component of image gradient vector
        temp = 0; %Temporary memory
        bw = 0; %Binary image
        bwl = 0; %Binary image
        partnum =0; %detected particle number
        tA = 0; %Active area size of the particles
        tI = 0; %Average intensity value within active area
        tR = 0; %

        dCent = 0; %(x,y) coordinates of the particles
        bins = 100; %bins for histogram
        avg = 0; %avg value for thresholding
        caltime = 0; %calculation time
        
        CalcMethod = 1; %Calculation method
        Rout = 0; %Calulation parameter
        mask = 0; %Combination of binary images
        
        success = 0; %Logical for calculation
        
    end
    methods
        function obj = PosFinder(im, ht, ll, met, ro) %Main class function 
            obj.imFull = im;
            obj.CamSize = size(obj.imFull);
            obj.avg = mean(obj.imFull(:));
            obj.th = ht;
            obj.L = ll;
            obj.CalcMethod = met;
            obj.Rout = ro;
            [obj.X, obj.Y] = meshgrid((1:obj.CamSize(2)), (1:obj.CamSize(1)));
            [obj.dx, obj.dy] = obj.gradim();
            tic;
            obj.bw = obj.segmentation;
            obj.bwl = obj.connectivity;
            obj.bwl = obj.elimination;
            obj.partnum = max(obj.bwl(:));
            [obj.dCent, obj.tA, obj.tI, obj.mask] = obj.FindPos;
            obj.tR = sqrt(obj.tA./pi);
            obj.caltime = toc;
            obj.success = 1;

        end
        function disp_caltime(obj) %Display time on the panel
            disp(['Elapsed time is ' num2str(obj.caltime)]);
        end
        function show_image(obj) %Show image for command line version
            image(obj.imFull), colormap(gray(256))
            title('Image and Positions')
            hold on
            plot(obj.dCent(:,1),obj.dCent(:,2),'b.')
            rectangle('Position',[obj.L, obj.L, obj.CamSize(2)-2*obj.L, obj.CamSize(1)-2*obj.L],'EdgeColor','r')
            axis equal
            hold off
            drawnow;
        end
        function show_imgradients(obj) %Show image gradients for command line version
            image(obj.imFull+obj.mask*50), colormap(gray(256))
            title('Image Gradients and Positions')
            hold on
            plot(obj.dCent(:,1),obj.dCent(:,2),'b.')
            rectangle('Position',[obj.L, obj.L, obj.CamSize(2)-2*obj.L, obj.CamSize(1)-2*obj.L],'EdgeColor','r')
            quiver(obj.X.*obj.mask, obj.Y.*obj.mask, obj.dx.*obj.mask, obj.dy.*obj.mask,1)
            axis equal
            hold off
            drawnow;
        end
        function show_bw(obj) %Show binary image for command line version
            figure, image(obj.bw*255), colormap(gray(256))
            axis equal
            drawnow;
        end
        function show_mask(obj) %Show result mask for command line version
            if obj.mask ~= 0 
            figure, image(obj.mask*255), colormap(gray(256))
            axis equal
            drawnow;
            else
                warning('The mask is zero. mask is calculated for method 3')
            end
        end
        function hist_tA(obj) %Calculation tA parameter
            [counts,vals] = hist(obj.tA,obj.bins);
            figure, plot(vals,counts,'k*')
            drawnow;
        end
        function hist_tI(obj) %Calculation tI parameter
            [counts,vals] = hist(obj.tI,obj.bins);
            figure, plot(vals,counts,'k*')
            drawnow;
        end
        function hist_im(obj) %Show histogram for command line version
            figure, imhist(obj.imFull/255)
            drawnow;
        end
        function show_panel(obj) %Show graphical panel for command line version
            subplot(2,2,1)
                image(obj.imFull), colormap(gray(256))
                title('Image and Positions')
                hold on
                plot(obj.dCent(:,1),obj.dCent(:,2),'b.')
                rectangle('Position',[obj.L, obj.L, obj.CamSize(2)-2*obj.L, obj.CamSize(1)-2*obj.L],'EdgeColor','r')
                axis equal
                hold off
                drawnow;
            subplot(2,2,2)
                image(obj.bw*255), colormap(gray(256))
                title('Particle Regions')
                axis equal
                drawnow;
            subplot(2,2,3)
                [counts,vals] = hist(obj.tA,obj.bins);
                plot(vals,counts,'k*')
                title('Particle Size Distribution')
                drawnow;
            subplot(2,2,4)
                imhist(obj.imFull/255)
                title('Image Histagram')
                drawnow;
        end
    end
    methods
        function bw = segmentation(obj) %Binary image segmentation (pixel connectivity)
            bw2 = obj.imFull;
            bw2(bw2<obj.avg)=obj.avg;
            bw2 = (bw2-min(bw2(:)))/(max(bw2(:))-min(bw2(:)))*255;
            bw = bw2;
            bw(bw <= obj.th) = 0;
            bw(bw > obj.th) = 1;
        end
        function bwl = connectivity(obj) %Pixel connectivity function
             ss=obj.CamSize;
            
            bwt=uint16(obj.bw);

            sayac=1;

            for j=obj.L+1:ss(2)-obj.L
                for i=obj.L+1:ss(1)-obj.L
            %         list=NaN;
                    if bwt(i,j)==1

                        sayac=sayac+1;
                        bwt(i,j)=sayac;
                        list=[i,j];
                        cik=0;
                        while cik==0
                            list2=NaN;
                            s=0;
                            df=size(list);
                            for h=1:df(1)
                                if list(h,1)-1>=1
                                   if bwt(list(h,1)-1,list(h,2))==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1)-1,list(h,2)];
                                       bwt(list(h,1)-1,list(h,2))=sayac;
                                   end
                                end
                                if list(h,1)+1<=ss(1)
                                   if bwt(list(h,1)+1,list(h,2))==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1)+1,list(h,2)];
                                       bwt(list(h,1)+1,list(h,2))=sayac;
                                   end
                                end
                                if list(h,2)-1>=1
                                   if bwt(list(h,1),list(h,2)-1)==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1),list(h,2)-1];
                                       bwt(list(h,1),list(h,2)-1)=sayac;
                                   end
                                end
                                if list(h,2)+1<=ss(2)
                                   if bwt(list(h,1),list(h,2)+1)==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1),list(h,2)+1];
                                       bwt(list(h,1),list(h,2)+1)=sayac;
                                   end
                                end
                                if (list(h,1)+1<=ss(1)) && (list(h,2)+1<=ss(2))
                                   if bwt(list(h,1)+1,list(h,2)+1)==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1)+1,list(h,2)+1];
                                       bwt(list(h,1)+1,list(h,2)+1)=sayac;
                                   end
                                end
                                if (list(h,1)+1<=ss(1)) && (list(h,2)-1>=1)
                                   if bwt(list(h,1)+1,list(h,2)-1)==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1)+1,list(h,2)-1];
                                       bwt(list(h,1)+1,list(h,2)-1)=sayac;
                                   end
                                end
                                if (list(h,1)-1>=1) && (list(h,2)-1>=1)
                                   if bwt(list(h,1)-1,list(h,2)-1)==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1)-1,list(h,2)-1];
                                       bwt(list(h,1)-1,list(h,2)-1)=sayac;
                                   end
                                end
                                if (list(h,1)-1>=1) && (list(h,2)+1<=ss(2))
                                   if bwt(list(h,1)-1,list(h,2)+1)==1
                                       s=s+1;
                                       list2(s,1:2)=[list(h,1)-1,list(h,2)+1];
                                       bwt(list(h,1)-1,list(h,2)+1)=sayac;
                                   end
                                end
                            end

                            if isnan(list2)
                                cik=1;
                            else
                                list=list2;
                            end


                        end

                    end
                end
            end

            bwl=double(bwt-1);


        end
        function bwll = elimination(obj) %Elimination bad binary particle regions
            num = max(obj.bwl(:));
            bwll = zeros(obj.CamSize(1), obj.CamSize(2));
            n = 0;
            for i = 1 : num
                m = obj.bwl;
                m(m ~= i) = 0;
                m(m == i) = 1;
                if sum(m(:)) > 8
                    n = n + 1;
                    bwll = bwll + n*m;
                end
            end
        end
        function [ xcent, ycent ] = centroid(obj, L1) %Centroid algorithm
            im1=obj.imFull.*L1;

            top1=sum(sum(im1.*obj.X));
            top2=sum(sum(im1.*obj.Y));
            top3=sum(sum(im1));

            xcent=top1/top3;
            ycent=top2/top3;
        end
        function [cents, tA, tI, mask] = FindPos(obj) %Main function for finding positions
            tA = zeros(obj.partnum,1);
            tI = zeros(obj.partnum,1);
            cents = zeros(obj.partnum,2);
            mask = 0;
            if obj.CalcMethod == 3
                efarea=zeros(obj.CamSize(1),obj.CamSize(2),obj.partnum);
                area=zeros(obj.CamSize(1),obj.CamSize(2),obj.partnum); 
            end
            for k = 1:obj.partnum
                L2=obj.bwl;
                L2(L2~=k)=0;
                L2=L2/k;
                mask = mask + L2;
                tA(k) = sum(sum(L2));
                tI(k) = sum(sum(L2.*obj.imFull))/tA(k);

                switch obj.CalcMethod
                    case 1
                        [cents(k,1), cents(k,2)] = obj.centroid(L2);
                    case 2
                        [cents(k,1), cents(k,2)] = obj.radial(L2);
                    case 3
                        [cents(k,1), cents(k,2)] = obj.radial(L2);
                        rx=cents(k,1)-obj.X;
                        ry=cents(k,2)-obj.Y;
                        r=sqrt(rx.^2+ry.^2);
                        r(r>obj.Rout)=0;
                        r(r>0)=1;
                        area(:,:,k)=L2;
                        efarea(:,:,k)=r;
                end
            end
            if obj.CalcMethod == 3
                [cents, mask] = obj.parRadial(cents, area, efarea);
            end
        end
        function [dx, dy] = gradim(obj) %Image gradient function
            gx=[1,1,0,-1,-1;
                1,1,0,-1,-1;
                1,1,0,-1,-1];
            gy=[1,1,1;
                1,1,1;
                0,0,0;
                -1,-1,-1;
                -1,-1,-1];
            dx=conv2(obj.imFull/255,gx,'same');
            dy=conv2(obj.imFull/255,gy,'same');
        end
        function [xc, yc] = radial(obj, L1) %RSM algorithm
            w=sqrt(obj.dx.^2+obj.dy.^2);
            w=w.*L1;
            % theta=atan2(dy,dx);
            % m=tan(theta);
            m=obj.dy./obj.dx;
            m(isnan(m))=0;
            m(isinf(m))=0;
            A=sum(sum(w.*m.^2./(m.^2+1)));
            B=sum(sum(-w.*m./(m.^2+1)));
            C=sum(sum(-w.*m./(m.^2+1)));
            D=sum(sum(w./(m.^2+1)));
            E=sum(sum(w.*m.*(m.*obj.X-obj.Y)./(m.^2+1)));
            F=sum(sum(-w.*(m.*obj.X-obj.Y)./(m.^2+1)));
            imat=[D, -B; -C, A]/(A*D-B*C);
            xc=imat(1,1)*E+imat(1,2)*F;
            yc=imat(2,1)*E+imat(2,2)*F;
            
            if xc < 1 || xc > obj.CamSize(2) || yc < 1 || yc > obj.CamSize(1)
                xc = NaN;
                yc = NaN;
            end
        end
        function [cents, mask] = parRadial(obj, cents, area, efarea) %pRSM algorithm
            mask=0;
            if obj.Rout>0
                if obj.partnum>1
%                     mask=0;
                    for k=1:obj.partnum
                        ar=zeros(obj.CamSize);
                        for g=1:obj.partnum
                            if (g~=k)
                                ar =  ar + 2*efarea(:,:,g);
                            end
                        end
                        ar = ar + area(:,:,k);
                        ar(ar~=1)=0;
                        if sum(ar(:)) > 50
                            [cents(k,1), cents(k,2)]=obj.radial(ar);
                        else
%                             warning('There is no undistorted area, ')
                        end
                        mask =  mask + ar;
                    end
                    
                end
            end
        end
    end
end
