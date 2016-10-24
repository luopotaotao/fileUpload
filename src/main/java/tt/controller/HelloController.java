package tt.controller;

import com.sun.org.glassfish.external.probe.provider.annotations.ProbeParam;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.annotation.SessionScope;
import tt.model.Clazz;
import tt.resumable.HttpUtils;
import tt.resumable.ResumableInfo;
import tt.resumable.ResumableInfoStorage;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Created by taotao on 2016/10/8.
 */
@Controller
@RequestMapping("hello")
public class HelloController {
    public static final String UPLOAD_DIR = "WEB-INF/resources/tmp";
    public static final String LOGO_DIR = "WEB-INF/resources/logo";
    @RequestMapping(value = "/", method = RequestMethod.GET)
    public Object index() {
        return "index";
    }

    @RequestMapping(value = "/post", method = RequestMethod.GET)
    public Object acceptData(@RequestBody Clazz clazz) {
        System.out.println(clazz);
        return null;
    }

    @RequestMapping(value = "/save",method = RequestMethod.POST)
    @ResponseBody
    public Map<String,Object> saveUploadFile(@RequestParam(value = "fileName") String filename, HttpSession session){
        Map<String,Object> ret = new HashMap<>();
        if(filename!=null&&!filename.isEmpty()){
            String upload_dir = session.getServletContext()
                    .getRealPath(UPLOAD_DIR)+File.separator+filename;
            String img_dir = session.getServletContext()
                    .getRealPath(LOGO_DIR)+File.separator+filename;
            Path source = Paths.get(upload_dir);
            Path nwdir = Paths.get(img_dir);

            try {
                Files.move(source,nwdir);
                ret.put("flag",1);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        if(!ret.containsKey("flag")){
            ret.put("flag",0);
        }
        return ret;
    }

    @RequestMapping(value = "upload", method = RequestMethod.POST)
    public void upload(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int resumableChunkNumber = getResumableChunkNumber(request);

        ResumableInfo info = getResumableInfo(request);

        RandomAccessFile raf = new RandomAccessFile(info.resumableFilePath, "rw");

        //Seek to position
        raf.seek((resumableChunkNumber - 1) * (long) info.resumableChunkSize);

        //Save to file
        InputStream is = request.getInputStream();
        long readed = 0;
        long content_length = request.getContentLength();
        byte[] bytes = new byte[1024 * 100];
        while (readed < content_length) {
            int r = is.read(bytes);
            if (r < 0) {
                break;
            }
            raf.write(bytes, 0, r);
            readed += r;
        }
        raf.close();


        //Mark as uploaded.
        info.uploadedChunks.add(new ResumableInfo.ResumableChunkNumber(resumableChunkNumber));
        if (info.checkIfUploadFinished()) { //Check if all chunks uploaded, and change filename
            ResumableInfoStorage.getInstance().remove(info);
            response.getWriter().print("{\"url\":\""+info.resumableFilename+"\"}");
        } else {
            response.getWriter().print("Upload");
        }
    }

    @RequestMapping(value = "upload", method = RequestMethod.GET)
    public void uploadStatus(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int resumableChunkNumber = getResumableChunkNumber(request);

        ResumableInfo info = getResumableInfo(request);

        if (info.uploadedChunks.contains(new ResumableInfo.ResumableChunkNumber(resumableChunkNumber))) {
            response.getWriter().print("Uploaded."); //This Chunk has been Uploaded.
        } else {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private int getResumableChunkNumber(HttpServletRequest request) {
        return HttpUtils.toInt(request.getParameter("resumableChunkNumber"), -1);
    }

    private ResumableInfo getResumableInfo(HttpServletRequest request) throws ServletException {
        String base_dir = request.getSession().getServletContext()
            .getRealPath(UPLOAD_DIR);
        System.out.println(base_dir);
        int resumableChunkSize = HttpUtils.toInt(request.getParameter("resumableChunkSize"), -1);
        long resumableTotalSize = HttpUtils.toLong(request.getParameter("resumableTotalSize"), -1);
        String resumableIdentifier = request.getParameter("resumableIdentifier");
//        String sourceName[] = request.getParameter("resumableFilename").split(".");
        String resumableFilename = UUID.randomUUID().toString()+".png";//request.getParameter("resumableFilename");
        String resumableRelativePath = request.getParameter("resumableRelativePath");
        //Here we add a ".temp" to every upload file to indicate NON-FINISHED
        new File(base_dir).mkdir();

        String resumableFilePath = new File(base_dir, resumableFilename).getAbsolutePath() + ".temp";

        ResumableInfoStorage storage = ResumableInfoStorage.getInstance();

        ResumableInfo info = storage.get(resumableChunkSize, resumableTotalSize,
                resumableIdentifier, resumableFilename, resumableRelativePath, resumableFilePath);
        if (!info.vaild()) {
            storage.remove(info);
            throw new ServletException("Invalid request params.");
        }
        return info;
    }
}
