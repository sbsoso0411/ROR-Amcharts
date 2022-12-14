module UploadHelper
  # def s3_uploader_form(options = {}, &block)
  #     uploader = S3Uploader.new(options)
  #     form_tag(uploader.url, uploader.form_options) do
  #         uploader.fields.map do |name, value|
  #             hidden_field_tag(name, value)
  #         end.join.html_safe + capture(&block)
  #     end
  # end
  #
  # class S3Uploader
  #     def initialize(options)
  #         @options = options.reverse_merge(
  #                 id: "fileupload",
  #                 aws_access_key_id: AWSConfig["AWS_ACCESS_KEY_ID"],
  #                 aws_secret_access_key: AWSConfig["AWS_SECRET_ACCESS_KEY"],
  #                 bucket: AWSConfig["BUCKET"],
  #                 acl: "private",
  #                 expiration: 10.days.from_now.utc,
  #                 max_file_size: 100.megabytes,
  #                 as: "file"
  #         )
  #     end
  #
  #     def form_options
  #         {
  #                 id: @options[:id],
  #                 method: "post",
  #                 authenticity_token: false,
  #                 multipart: true,
  #                 data: {
  #                         post: @options[:post],
  #                         as: @options[:as]
  #                 }
  #         }
  #     end
  #
  #     def fields
  #         {
  #                 :key => key,
  #                 :acl => @options[:acl],
  #                 :policy => policy,
  #                 :signature => signature,
  #                 "AWSAccessKeyId" => @options[:aws_access_key_id],
  #         }
  #     end
  #
  #     def key
  #         @key ||= "#{UserObserver.current_user.company.test_company ? 'test/' : '' }#{UserObserver.current_user.company_id}/#{SecureRandom.hex}/${filename}"
  #     end
  #
  #     def url
  #         "https://s3.amazonaws.com/#{@options[:bucket]}/"
  #     end
  #
  #     def policy
  #         Base64.encode64(policy_data.to_json).gsub("\n", "")
  #     end
  #
  #     def policy_data
  #         {
  #                 expiration: @options[:expiration],
  #                 conditions: [
  #                         ["starts-with", "$utf8", ""],
  #                         ["starts-with", "$key", ""],
  #                         ["content-length-range", 0, @options[:max_file_size]],
  #                         ["starts-with","$content-type", @options[:content_type_starts_with] ||""],
  #                         {bucket: @options[:bucket]},
  #                         {acl: @options[:acl]}
  #                 ]
  #         }
  #     end
  #
  #     def signature
  #         Base64.encode64(
  #                 OpenSSL::HMAC.digest(
  #                         OpenSSL::Digest::Digest.new('sha1'),
  #                         @options[:aws_secret_access_key], policy
  #                 )
  #         ).gsub("\n", "")
  #     end
  # end

  def s3_bucket_url ssl = true
    S3DirectUpload.config.url || "http#{ssl ? 's' : ''}://#{S3DirectUpload.config.bucket}.s3.amazonaws.com/"
  end
end