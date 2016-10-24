<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Resumable.js - Multiple simultaneous, stable and resumable uploads via the HTML5 File API</title>
    <meta charset="UTF-8">
    <link rel="stylesheet" type="text/css" href="../resources/css/style.css"/>
    <link rel="stylesheet" type="text/css" href="../resources/css/default/easyui.css">
    <link rel="stylesheet" type="text/css" href="../resources/css/icon.css">
    <script type="text/javascript" src="../resources/js/jquery-1.11.3.js"></script>
    <script type="text/javascript" src="../resources/js/jquery.easyui.min.js"></script>
    <script type="text/javascript" src="../resources/js/easyui-lang-zh_CN.js"></script>
    <script src="../resources/js/resumable.js"></script>
</head>
<body>
<div id="dlg_edit" class="easyui-dialog" style="width:100%;max-width:400px;padding:30px 60px;overflow: hidden">
    <form id="ff" class="easyui-form" method="post" data-options="novalidate:true" action="${baseUrl}/post.action">
        <div style="margin-bottom:20px;display: none">
            <input class="easyui-textbox" name="id" style="width:100%" data-options="label:'企业编号:',required:true">
        </div>
        <div style="margin-bottom:20px">
            <input class="easyui-textbox" name="name" style="width:100%"
                   data-options="label:'单位名称:',required:true">
        </div>
        <div style="margin-bottom:20px">
            <input class="easyui-textbox" name="contacts" style="width:100%"
                   data-options="label:'联系人:'">
        </div>
        <div style="margin-bottom:20px">
            <input class="easyui-numberbox" name="tel" style="width:100%"
                   data-options="label:'电话号码:'">
        </div>
        <div style="margin-bottom:20px">
            <%--<div class="resumable-drop" ondragenter="jQuery(this).addClass('resumable-dragover');"--%>
                 <%--ondragend="jQuery(this).removeClass('resumable-dragover');"--%>
                 <%--ondrop="jQuery(this).removeClass('resumable-dragover');">--%>
                <%--拖动Logo文件到此处 或者 <a class="resumable-browse"><u>点击选择文件</u></a>--%>
            <%--</div>--%>
            <input class="easyui-textbox resumable-browse" style="width:100%"
                   data-options="label:'logo文件:',buttonText:'选择'">
            <div class="resumable-progress">
                <table>
                    <tr>
                        <td width="100%">
                            <div class="progress-container">
                                <div class="progress-bar"></div>
                            </div>
                        </td>
                        <td class="progress-text" nowrap="nowrap"></td>
                        <td class="progress-pause" nowrap="nowrap">
                            <a href="#" onclick="r.upload(); return(false);" class="progress-resume-link"><img
                                    src="../resources/imgs/resume.png" title="恢复"/></a>
                            <a href="#" onclick="r.pause(); return(false);" class="progress-pause-link"><img
                                    src="../resources/imgs/pause.png" title="暂停"/></a>
                        </td>
                    </tr>
                </table>

            </div>
        </div>
        <div style="margin-bottom:20px;height: 100px;overflow: hidden">
            <img id="img" src="../resources/logo/blank.png"/>
        </div>
    </form>

    <input id="fileName">
    <button id="btn_save">保存</button>
    <div class="resumable-error">
        抱歉,您的浏览器版本过低,不支持文件上传!
    </div>





    <%--<ul class="resumable-list"></ul>--%>

    <script>
        var r = new Resumable({
            target: '/hello/upload',
            chunkSize: 1 * 1024 * 1024,
            simultaneousUploads: 4,
            testChunks: true,
            throttleProgressCallbacks: 1,
            method: "octet"
        });
        // Resumable.js isn't supported, fall back on a different method
        if (!r.support) {
            $('.resumable-error').show();
        } else {
            // Show a place for dropping/selecting files
            $('.resumable-drop').show();
            $.each($('.resumable-drop'),function (i,item) {
                debugger
                r.assignDrop(item);
            });
            $.each($('.resumable-browse'),function (i,item) {
                debugger
                r.assignBrowse(item);
            });
//            r.assignDrop($('.resumable-drop')[0]);
//            r.assignBrowse($('.resumable-browse')[0]);

            // Handle file add event
            r.on('fileAdded', function (file) {
                // Show progress pabr
                $('.resumable-progress, .resumable-list').show();
                // Show pause, hide resume
                $('.resumable-progress .progress-resume-link').hide();
                $('.resumable-progress .progress-pause-link').show();
                // Add the file to the list
//                $('.resumable-list').append('<li class="resumable-file-' + file.uniqueIdentifier + '">Uploading <span class="resumable-file-name"></span> <span class="resumable-file-progress"></span>');
//                $('.resumable-file-' + file.uniqueIdentifier + ' .resumable-file-name').html(file.fileName);
                // Actually start the upload
                r.upload();
            });
            r.on('pause', function () {
                // Show resume, hide pause
                $('.resumable-progress .progress-resume-link').show();
                $('.resumable-progress .progress-pause-link').hide();
            });
            r.on('complete', function () {
                // Hide pause/resume when the upload has completed
                $('.resumable-progress .progress-resume-link, .resumable-progress .progress-pause-link').hide();
            });
            r.on('fileSuccess', function (file, message) {
                message = $.parseJSON(message);
                $('#fileName').val(message.url);
                $('#img').attr('src', '../resources/tmp/' + message.url);
                console.log('完成:' + message);
                // Reflect that the file upload has completed
                $('.resumable-file-' + file.uniqueIdentifier + ' .resumable-file-progress').html('(completed)');
            });
            r.on('fileError', function (file, message) {
                // Reflect that the file upload has resulted in error
                $('.resumable-file-' + file.uniqueIdentifier + ' .resumable-file-progress').html('(file could not be uploaded: ' + message + ')');
            });
            r.on('fileProgress', function (file) {
                // Handle progress for both the file and the overall upload
                $('.resumable-file-' + file.uniqueIdentifier + ' .resumable-file-progress').html(Math.floor(file.progress() * 100) + '%');
                $('.progress-bar').css({width: Math.floor(r.progress() * 100) + '%'});
            });
        }
        $('#btn_save').on('click', function () {
            $.ajax({
                url: 'save',
                type: 'post',
                dataType: 'json',
                data: {fileName:$('#fileName').val()}
            }).done(function (ret) {
                if(ret.flag){
                    console.log('保存成功');
                }else{
                    console.log("保存失败");
                }
            }).fail(function () {
                console.log("保存失败");
            });
        })
    </script>

</div>
</body>
</html>



